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
# Example usage:
# ./wordle.rb crane-..... sloth-..y.. opium-y.g.g (answer is "idiom")
#
# TODO: Examine the possible dictionary matches after filtering,
# and do the bucketing analysis used by NYTimes's WordleBot.
alphabet = ('a'..'z').to_a

# For each letter, the smallest or largest number of times it might appear
# in the entire word
# $occurrences['g'] => (0..3)
$occurrences = Hash[
  alphabet.map { |let| [let, (0..3)] }
]

# For a given position, the possible letters it might contain
# $positions[2] => ['a', 'b', 'd', ... 'z']
$positions = (0..4).map { alphabet.dup }

def go(word, outcome)
  # (0..4).group_by { |p| 'nanny'[p] } => {"n"=>[0, 2, 3], "a"=>[1], "y"=>[4]}
  letter_counts = (0..4).group_by { |p| word[p] }

  letter_counts.each_pair do |letter, positions| # 'n', [0, 2, 3]
    count_in_guess = positions.size # 1..3
    outcomes = positions.map { |pos| [pos, outcome[pos]] } # [[0, '.'], [2, 'y'], [3, '.']]

    gray_count = outcomes.count { |r| r.last == '.' }
    if gray_count > 0
      # With at least one gray, we know exactly how many of that letter are in the word
      exact_count = count_in_guess - gray_count # 3 N's, 2 are gray: max_count = 1
    else
      # If there are no gray outcomes, we only know there are _at least_ that many
      min_count = count_in_guess
    end

    # Apply new information about increased minimum count or decreased maximum count
    old_range = $occurrences[letter]
    new_min = [old_range.min, (min_count || 0), (exact_count || 0)].max
    new_max = [old_range.max, (exact_count || 3)].min
    $occurrences[letter] = (new_min..new_max)

    # With only gray outcomes, eliminate the letter from all consideration
    if exact_count == 0
      $positions.each { |pos| pos.delete(letter) }
    end

    outcomes.each do |(pos, an_outcome)|
      case an_outcome
      when 'g' # We absolutely know this letter is here, all other possibilites are removed
        $positions[pos].clear
        $positions[pos] << letter
      when 'y', '.' # We only know the letter isn't here
        $positions[pos].delete(letter)
      else raise "Unexpected char in outcome '#{outcome}': '#{an_outcome}'"
      end
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

# Construct a Regexp to filter out words with letters where we know they ain't
# When there's just one possibility, simply state the letter
# When there are more than one, construct a character class with square brackets
segs = $positions.map { |av| av.size == 1 ? av.first : (['['] + av + [']']).join('') }.join('')
pat = Regexp.new("^#{segs}$")
puts("Searching for: #{pat}")
puts("Required: #{$occurrences.inspect}")

all = File.read('/home/ec2-user/words/wordle-words.txt').split("\n")

# First filter by the Regexp, then count letters and filter by $occurrences
matches = all.grep(pat).keep_if do |word|
  split_word = word.split('')
  $occurrences.all? do |(letter, range)|
    next true if range == (0..3) # matches everything, tells us nothing
    letter_count = split_word.count { |lttr| lttr == letter }
    range.include?(letter_count)
  end
end

puts(matches.inspect)
