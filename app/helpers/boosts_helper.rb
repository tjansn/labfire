require "digest"

module BoostsHelper
  def boost_stacks_for(message)
    boosts = if message.association(:boosts).loaded?
      message.boosts.sort_by { |boost| [ boost.created_at, boost.id ] }
    else
      message.boosts.ordered.includes(:booster).to_a
    end

    Boost::Stack.build(boosts)
  end

  def boost_stack_dom_id(message, stack)
    "#{dom_id(message, :boost_stack)}_#{Digest::SHA256.hexdigest(stack.dom_key).first(12)}"
  end

  def boost_reaction_dom_id(message, content)
    "#{dom_id(message, :boost_reaction)}_#{Digest::SHA256.hexdigest(content).first(12)}"
  end

  def boost_reaction_label(contents)
    contents.to_sentence
  end
end
