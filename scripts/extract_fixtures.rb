require 'json'

collection = JSON.parse(File.read('docs/postman-collection.json'))

fixtures_dir = 'spec/fixtures'
Dir.mkdir(fixtures_dir) unless Dir.exist?(fixtures_dir)

count = 0

collection['item'].each do |section|
  section_name = section['name'].downcase.gsub(' ', '_').gsub(/[^a-z0-9_]/, '')
  next if section_name.include?('desenvolvimento')
  
  (section['item'] || []).each do |endpoint|
    method = endpoint.dig('request', 'method') || 'UNKNOWN'
    responses = endpoint['response'] || []
    
    responses.each_with_index do |resp, idx|
      next unless resp['code'] && resp['code'] < 300
      next unless resp['body']
      
      begin
        body = JSON.parse(resp['body'])
        key = "#{section_name}_#{method.downcase}_#{idx}"
        File.write("#{fixtures_dir}/#{key}.json", JSON.pretty_generate(body))
        puts "Created: #{key}.json"
        count += 1
      rescue JSON::ParserError
        # skip
      end
    end
  end
end

puts "\nTotal: #{count} fixtures"
