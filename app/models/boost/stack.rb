class Boost::Stack
  attr_reader :boosters, :contents, :boosts_by_content

  def self.build(boosts)
    stacks_by_booster_set = {}

    boosts.group_by(&:content).each do |content, content_boosts|
      boosters = unique_boosters_for(content_boosts)
      key = boosters.map(&:id).sort

      stack = stacks_by_booster_set[key] ||= new(boosters)
      stack.add(content, content_boosts)
    end

    stacks_by_booster_set.values
  end

  def initialize(boosters)
    @boosters = boosters
    @contents = []
    @boosts_by_content = {}
  end

  def add(content, boosts)
    contents << content
    boosts_by_content[content] = boosts
  end

  def boosts_for(content)
    boosts_by_content.fetch(content)
  end

  def visible_boosters(limit: 3)
    boosters.first(limit)
  end

  def hidden_booster_count(limit: 3)
    [ boosters.size - limit, 0 ].max
  end

  def dom_key
    ([ boosters.map(&:id).sort.join("-") ] + contents).join("-")
  end

  private
    def self.unique_boosters_for(boosts)
      boosters = []
      seen_booster_ids = {}

      boosts.each do |boost|
        next if seen_booster_ids[boost.booster_id]

        boosters << boost.booster
        seen_booster_ids[boost.booster_id] = true
      end

      boosters
    end
end
