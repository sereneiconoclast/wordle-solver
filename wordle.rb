#!/home/ec2-user/.asdf/shims/ruby
# Make a guess in Wordle (start with 'crane') and note the results.
# Run this program with the word, then a dash, then five characters
# describing the outcome: . for gray (not present), y for yellow
# (present but not in this position), g for green (letter is in right
# position).
#
# Then make another guess, rerun the program and add another word and its
# outcome to narrow the field of possibilities further.
#
# For now, with a double letter where one is yellow and the other gray,
# enter yellow as the outcome for both. If one is green and the other gray,
# enter green and yellow.
#
# Example usage:
# ./wordle.rb crane-..... sloth-..y.. opium-y.g.g (answer is "idiom")
#
# TODO, part 1: Keep track of how many occurrences of each letter are
# possible, e.g.:
# {
#   'a' => (0..3), # I don't think any word has more than 3 of the same letter
#   'b' => (0..3),
#   'c' => (0..3),
#   ...
# }
#
# When a gray letter shows up, set the range to (0..0).
# More useful: Use this whenever one or more yellow letters show up.
# Examine the outcome to control for how many of the letter might be there.
# If there's only one occurrence and it's yellow, zero is eliminated so
# change the range to (1..3).
# If there are two occurrences, one yellow and one gray, then the range is
# just (1..1) - this is also the case if one is green and one gray.
# If there are two and they're both yellow (or green), the range is (2..3).
# If there are three and two are yellow (or green), it's (2..2).
# If there are three and they're all yellow... well that's impossible.
#
# TODO, part 2: Examine the possible dictionary matches after filtering,
# and do the bucketing analysis used by NYTimes's WordleBot.
alphabet = (97..122).map(&:chr)
$available = (0..4).map { alphabet.dup }

$required = []

def go(word, outcome)
  (0..4).each do |i|
    av = $available[i]
    w = word[i..i]
    o = outcome[i..i]
    case o
    when '.' # Gray - letter appears in none of the 5 positions
      # TODO: Deal with double letter having one gray outcome, one yellow
      # This "completely rule out the letter" logic only works when every
      # occurrence of the letter in the guess is gray (which is usually
      # because the letter only occurs once)
      $available.each { |av2| av2.delete(w) }
    when 'g' # Green - letter is definitely in this position
      av.clear
      av << w
    when 'y'
      av.delete(w)
      $required << w unless $required.include?(w)
    else raise "Unexpected char in outcome '#{outcome}': '#{o}'"
    end
  end
end

ARGV.each do |arg|
  raise "Must be exactly 11 characters long: '#{arg}'" unless arg.size == 11
  raise "Must be a word followed by an outcome: '#{arg}'" unless arg[5..5] == '-'
  word = arg[0..4]
  outcome = arg[6..10]
  go(word, outcome)
end

segs = $available.map { |av| av.size == 1 ? av.first : (['['] + av + [']']).join('') }.join('')
pat = Regexp.new("^#{segs}$")
puts("Searching for: #{pat}")
puts("Required: #{$required.inspect}")

all = File.read('/home/ec2-user/words/wordle-words.txt').split("\n")
matches = all.grep(pat)
$required.each do |req|
  matches.keep_if { |word| word.include?(req) }
end

puts(matches.inspect)
