require 'anemone'
require 'Nokogiri'

class PubmedUtils
	def self.parseEmail(page)
		regex_email_address =  /([\w\-\_\.]+@{1}[\w\-\_]+(\.[\w\-\_]+)+)/
		doc = Nokogiri::HTML.parse(page.body)
		table = [] #note: index0 will remain "nil" and need to be ignored
		children_nodes = doc.xpath("//*[@id='maincontent']/div/div[5]/div/div[2]").children
		page_title = doc.xpath("//*[@id='maincontent']/div/div[5]/div/h1").text
		# p "page title"
		# p page_title
		# p "page title"
		sup_num = 0 #initial state
		doctor_name = "place holder"
		children_nodes.each do |child|
			#text should be skipped
			if child.class.name == "Nokogiri::XML::Text" then
				next
			end

			if child.name =="a" then
				doctor_name = child.text
			elsif child.name == "sup" then
				num = child.text[0].to_i
				if table[num].nil?
					table[num] = {"name"=>Array[doctor_name], "email"=>"default", "description"=>"default", "url"=>"default", "paper_title"=>"default", "hasEmail"=>false}
				else
					table[num]["name"].push(doctor_name)
				end
			else
				p "no match tags!!"
			end
		end

		num_items = table.length

		for row_num in 1..(num_items-1) do
			str = doc.xpath("//*[@id='maincontent']/div/div[5]/div/div[3]/ul/li[#{row_num}]/text()").text
			num = doc.xpath("//*[@id='maincontent']/div/div[5]/div/div[3]/ul/li[#{row_num}]/sup").text.to_i

			if str.length==0 
				p "break!!!!!!!!!!"
				break
			end

			if str.include?("@") then
				matches = str.match(regex_email_address)
				table[num]["email"] = matches[1]
				table[num]["description"] = str
				table[num]["hasEmail"]=true
				table[num]["url"]=page.url
				table[num]["page_title"]=page_title
			end
		end

		ret_array = []
		table.each do |item|
			if !item.nil? && item["hasEmail"]==true then
				ret_array.push(item)
			end
		end
		return ret_array
	end
end