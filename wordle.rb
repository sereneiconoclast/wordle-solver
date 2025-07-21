#!/home/ec2-user/.asdf/shims/ruby
#
# For now, with a double letter where one is yellow and the other gray,
# enter yellow as the outcome for both
#
# Example usage:
# ./wordle.rb crane-..... sloth-..y.. opium-y.g.g (answer is "idiom")
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
      # Needs to record that exactly one is present, but not in either position,
      # and only once in the word (so it needs to count occurrences)
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
