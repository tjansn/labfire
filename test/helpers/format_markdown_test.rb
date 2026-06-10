require "test_helper"

class FormatMarkdownTest < ActiveSupport::TestCase
  test "bolds single-star and double-star text" do
    assert_equal "<div>a <strong>bold</strong> word</div>", filter("<div>a *bold* word</div>")
    assert_equal "<div>a <strong>bold</strong> word</div>", filter("<div>a **bold** word</div>")
  end

  test "italicizes underscored text" do
    assert_equal "<div>an <em>italic</em> word</div>", filter("<div>an _italic_ word</div>")
  end

  test "strikes through tilde text" do
    assert_equal "<div>a <del>struck</del> word</div>", filter("<div>a ~struck~ word</div>")
  end

  test "renders inline code spans without formatting their contents" do
    assert_equal "<div>some <code>*code*</code> here</div>", filter("<div>some `*code*` here</div>")
  end

  test "renders markdown links" do
    assert_equal %(<div><a href="https://example.com/x" target="_blank" rel="noreferrer">Example</a></div>),
      filter("<div>[Example](https://example.com/x)</div>")
  end

  test "supports nested inline styles" do
    assert_equal "<div><strong>bold <em>italic</em></strong></div>", filter("<div>*bold _italic_*</div>")
  end

  test "leaves snake_case words and mid-word delimiters alone" do
    assert_equal "<div>foo_bar_baz stays</div>", filter("<div>foo_bar_baz stays</div>")
  end

  test "leaves URLs containing markdown characters alone" do
    assert_equal "<div>https://example.com/a_b_c~d</div>", filter("<div>https://example.com/a_b_c~d</div>")
  end

  test "does not format unbalanced delimiters" do
    assert_equal "<div>2 * 3 = 6 and 4 ~ 5</div>", filter("<div>2 * 3 = 6 and 4 ~ 5</div>")
  end

  test "converts single-line triple-backtick spans to pre blocks" do
    assert_equal "<div>look: <pre>x = 1</pre> neat</div>", filter("<div>look: ```x = 1``` neat</div>")
  end

  test "converts code fences to pre blocks" do
    assert_equal "<div>before<pre>line 1\nline 2</pre>after</div>",
      filter("<div>before<br>```<br>line 1<br>line 2<br>```<br>after</div>")
  end

  test "does not format markdown inside code fences" do
    assert_equal "<div><pre>*not bold*</pre></div>", filter("<div>```<br>*not bold*<br>```</div>")
  end

  test "escapes HTML inside code fences" do
    assert_equal "<div><pre>&lt;script&gt;alert(1)&lt;/script&gt;</pre></div>",
      filter("<div>```<br>&lt;script&gt;alert(1)&lt;/script&gt;<br>```</div>")
  end

  test "converts heading lines to heading tags" do
    assert_equal "<div><h1>Big news</h1>everyone</div>", filter("<div># Big news<br>everyone</div>")
    assert_equal "<div><h3>Smaller</h3></div>", filter("<div>### Smaller</div>")
  end

  test "leaves hashtags without a space alone" do
    assert_equal "<div>#winning</div>", filter("<div>#winning</div>")
  end

  test "formats inline styles within headings" do
    assert_equal "<div><h2>So <strong>bold</strong></h2></div>", filter("<div>## So *bold*</div>")
  end

  test "converts quoted lines to blockquotes" do
    assert_equal "<div><blockquote>wise words</blockquote>reply</div>",
      filter("<div>&gt; wise words<br>reply</div>")
  end

  test "merges consecutive quoted lines into one blockquote" do
    assert_equal "<div><blockquote>one<br>two</blockquote>reply</div>",
      filter("<div>&gt; one<br>&gt; two<br>reply</div>")
  end

  test "formats inline styles within blockquotes" do
    assert_equal "<div><blockquote>so <strong>bold</strong></blockquote></div>",
      filter("<div>&gt; so *bold*</div>")
  end

  test "does not format inside existing pre or code blocks" do
    assert_equal "<pre>*not bold*</pre>", filter("<pre>*not bold*</pre>")
    assert_equal "<div><code>_nope_</code></div>", filter("<div><code>_nope_</code></div>")
  end

  test "does not format inside link text" do
    assert_equal %(<div><a href="https://example.com">*nope*</a></div>),
      filter(%(<div><a href="https://example.com">*nope*</a></div>))
  end

  test "leaves plain text untouched" do
    assert_equal "<div>nothing fancy here</div>", filter("<div>nothing fancy here</div>")
  end

  private
    def filter(html)
      ContentFilters::FormatMarkdown.apply(ActionText::Content.new(html, canonicalize: false)).to_html
    end
end
