class ContentFilters::FormatMarkdown < ActionText::Content::Filter
  SYNTAX_HINT = /[*_~`]|\[[^\[\]]+\]\(|^>\s?|^\#{1,6}[ ]/m

  FENCE_LINE = /\A```[ ]?(\w[\w+-]*)?[ ]*\z/
  QUOTE_LINE = /\A>[ ]?/
  HEADING_LINE = /\A(?<level>\#{1,6})[ ]+(?<text>.+)\z/

  INLINE_TOKEN = %r{
      (?<url>https?://[^\s<>]+)
    | \[(?<label>[^\[\]\n]+)\]\((?<href>https?://[^\s()<>]+)\)
    | ```(?<fence>[^`\n]+?)```
    | `(?<code>[^`\n]+)`
    | \*\*(?<strong2>[^\s*](?:[^*\n]*[^\s*])?)\*\*
    | (?<![\w*])\*(?<strong>[^\s*](?:[^*\n]*[^\s*])?)\*(?![\w*])
    | (?<![\w_])_(?<em>[^\s_](?:[^_\n]*[^\s_])?)_(?![\w_])
    | (?<![\w~])~(?<del>[^\s~](?:[^~\n]*[^\s~])?)~(?![\w~])
  }x

  SKIP_INSIDE = %w[ pre code a action-text-attachment actiontext-opengraph-embed figcaption ]

  def applicable?
    content.to_plain_text.match?(SYNTAX_HINT)
  end

  def apply
    fragment.update do |source|
      source.css("div, p").each do |block|
        format_code_fences block
        format_headings block
        format_block_quotes block
      end
      format_inline_styles source
    end
  end

  private
    def format_code_fences(block)
      while (fences = fence_marker_nodes(block)).size >= 2
        convert_fence block, fences[0], fences[1]
      end
    end

    def fence_marker_nodes(block)
      block.children.select { |child| child.text? && child.text.strip.match?(FENCE_LINE) }
    end

    def convert_fence(block, opening, closing)
      interior = nodes_between(opening, closing)
      code = interior.map { |node| br?(node) ? "\n" : node.text }.join.delete_prefix("\n").delete_suffix("\n")

      pre = Nokogiri::XML::Node.new("pre", block.document)
      pre.content = code

      leading_br = opening.previous_sibling
      trailing_br = closing.next_sibling

      interior.each(&:remove)
      closing.remove
      opening.replace(pre)

      leading_br.remove if br?(leading_br)
      trailing_br.remove if br?(trailing_br)
    end

    def nodes_between(first, last)
      nodes = []
      node = first.next_sibling
      while node && node != last
        nodes << node
        node = node.next_sibling
      end
      nodes
    end

    def format_headings(block)
      heading_nodes = block.children.select do |child|
        child.text? && line_start?(child) && child.text.match?(HEADING_LINE)
      end

      heading_nodes.each do |node|
        match = node.text.match(HEADING_LINE)

        heading = Nokogiri::XML::Node.new("h#{match[:level].length}", block.document)
        heading.content = match[:text]

        leading_br = node.previous_sibling
        trailing_br = node.next_sibling

        node.replace(heading)

        leading_br.remove if br?(leading_br)
        trailing_br.remove if br?(trailing_br)
      end
    end

    def format_block_quotes(block)
      quote_line_groups(block).each do |nodes|
        quote = Nokogiri::XML::Node.new("blockquote", block.document)

        nodes.each do |node|
          if br?(node)
            quote.add_child Nokogiri::XML::Node.new("br", block.document)
          else
            quote.add_child Nokogiri::XML::Text.new(node.text.sub(QUOTE_LINE, ""), block.document)
          end
        end

        leading_br = nodes.first.previous_sibling
        trailing_br = nodes.last.next_sibling

        nodes.first.replace(quote)
        nodes.drop(1).each(&:remove)

        leading_br.remove if br?(leading_br)
        trailing_br.remove if br?(trailing_br)
      end
    end

    def quote_line_groups(block)
      groups, current = [], nil

      block.children.each do |node|
        if quote_line?(node)
          (current ||= []) << node
        elsif br?(node) && current && quote_line?(node.next_sibling)
          current << node
        else
          groups << current if current
          current = nil
        end
      end

      groups << current if current
      groups
    end

    def quote_line?(node)
      node&.text? && node.text.match?(QUOTE_LINE) && line_start?(node)
    end

    def line_start?(node)
      previous = node.previous_sibling
      previous.nil? || br?(previous)
    end

    def br?(node)
      node&.element? && node.name == "br"
    end

    def format_inline_styles(source)
      text_nodes = []
      source.traverse do |node|
        text_nodes << node if node.text? && node.ancestors.none? { |ancestor| SKIP_INSIDE.include?(ancestor.name) }
      end

      text_nodes.each do |node|
        next unless node.text.match?(/[*_~`\[]/)

        @formatted = false
        html = render_inline(node.text)
        node.replace(html) if @formatted
      end
    end

    def render_inline(text)
      result = +""
      position = 0

      while (match = INLINE_TOKEN.match(text, position))
        result << escape(text[position...match.begin(0)])
        result << render_inline_token(match)
        position = match.end(0)
      end

      result << escape(text[position..])
    end

    def render_inline_token(match)
      case
      when match[:url]
        escape(match[:url])
      when match[:label]
        @formatted = true
        %(<a href="#{escape(match[:href])}" target="_blank" rel="noreferrer">#{render_inline(match[:label])}</a>)
      when match[:fence]
        @formatted = true
        "<pre>#{escape(match[:fence].strip)}</pre>"
      when match[:code]
        @formatted = true
        "<code>#{escape(match[:code])}</code>"
      when match[:strong2] || match[:strong]
        @formatted = true
        "<strong>#{render_inline(match[:strong2] || match[:strong])}</strong>"
      when match[:em]
        @formatted = true
        "<em>#{render_inline(match[:em])}</em>"
      when match[:del]
        @formatted = true
        "<del>#{render_inline(match[:del])}</del>"
      end
    end

    def escape(text)
      CGI.escapeHTML(text.to_s)
    end
end
