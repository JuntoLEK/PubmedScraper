require 'json'
require 'uri'
require 'net/http'
require 'Anemone'
require './PubmedUtils.rb'
require 'csv'


# BASE_URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmode=json&retmax=1000"
BASE_URL = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmode=json&retmax=1000"
ABSTRACT_PAGE_BASE_URL = "https://www.ncbi.nlm.nih.gov/pubmed/"
TERM = "&term="
RETSTART = "&retstart="
ESEARCHRESULT = "esearchresult"
RETMAX=1000

query_word = "spinal+fusion"
ret_start=0
id_list = []
search_page_url_list = []
abstract_page_url_list = []
array_for_output = []
header_for_output = []
output_file_name = "pubmed_result_of_#{query_word}.csv"
#----------------------------------------------------------------



#get first page and total count
uri = URI.parse(BASE_URL + RETSTART + ret_start.to_s + TERM + query_word)
json = Net::HTTP.get(uri)
result = JSON.parse(json)
total_count = result[ESEARCHRESULT]["count"].to_i
id_list.concat(result[ESEARCHRESULT]["idlist"])

#get ids
# num_page = total_count / RETMAX
num_page=1
(1..num_page).each do |page|
	ret_start = RETMAX * page
	search_page_url_list.push(BASE_URL + RETSTART + ret_start.to_s + TERM + query_word)
end
Anemone.crawl(search_page_url_list, :depth_limit => 0) do |anemone|
	anemone.on_every_page do |page|
		result = JSON.parse(page.body)
		id_list.concat(result[ESEARCHRESULT]["idlist"])
	end
end

#access to each page with ids and get email if they have it
id_list.each do |id|
	abstract_page_url_list.push(ABSTRACT_PAGE_BASE_URL + id)
end
Anemone.crawl(abstract_page_url_list, :depth_limit => 0) do |anemone|
	anemone.on_every_page do |page|
		table = PubmedUtils.parse_email(page)
		table.each do |item|
			array_for_output.push(item)
		end
	end
end

#generate output as csv
CSV.open(output_file_name,'w') do |row|
	row << PubmedUtils.generate_header
	array_for_output.each do |item|
		row << PubmedUtils.to_array_for_csv(item)
	end
end