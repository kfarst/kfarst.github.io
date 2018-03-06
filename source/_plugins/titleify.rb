# Replaces multiple newlines and whitespace
# between them with one newline

module TitleifyFilter
  def titleify(input)
    split_title = input.split('-')
    (split_title.size > 1 ? split_title.map { |word| word.capitalize } : split_title).join(' ')
  end
end

Liquid::Template.register_filter(TitleifyFilter)

