# A development Guardfile, meant to protect you during local development

guard :bundler do
  watch('Gemfile')
end

guard :rubocop do
  watch(%r{.+\.rb$})
  # watch(/file/)
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
