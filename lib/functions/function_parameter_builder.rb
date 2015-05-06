#
# for internal use only -
# please don't run me, or this
# package could be corrupted
#

module FPB

	require 'open-uri'
	require 'nokogiri'
	require 'json'
	require 'yaml'

	class YamlMap

		def initialize
			@reference_path			= './phpfunc.yml'
			@source_path				= '../../functions.json'
			@destination_path		= @source_path
		end

		def get_reference_yaml
			YAML.load(File.read(@reference_path))
		end

		def get_reference_hash
			#
			# parse yaml file into a nice
			# hash structure like {name: [args], name2:..}
			#
			reference_hash = {}
			reference_data = get_reference_yaml

			reference_data['functions'].each do |fn|
				name = fn.scan(/(?:^|(?:[.!?]\s))(\w+)/).flatten.first
				params = fn.split('[').first.scan(/\$(.*?)[\s\)\,]/).flatten
				params.map!{|x| '$'+x.to_s}
				reference_hash[name] = params
			end

			return reference_hash
		end

		def get_source_hash
			JSON.parse(File.read(@source_path))['functions']
		end

		def build
			reference_data 		= get_reference_hash
			source_data				= get_source_hash
			destination_data	= {functions:source_data}

			source_data.each_with_index do |sd, i|
				reference = reference_data[sd['text']]
				destination_data[:functions][i]['parameters'] = reference
			end

			File.open(@destination_path, "w") do |f|
				f.write(JSON.pretty_generate(destination_data))
			end
		end
	end

	class RemoteFetcher

		def initialize
			@fn_url 							= 'http://web.archive.org/web/20150108113252/http://php.net/manual/en/function.'
			@trunk_reference_url 	= 'http://svn.php.net/viewvc/phpdoc/en/trunk/reference/'
			@source_path					= '../../functions.json'
			@destination_path			= @source_path
		end

		def build(index = nil)
			input_data 			= JSON.parse(File.read(@source_path))
			final_data 			= input_data
			final_file			= @destination_path

			if index.nil?
				index = get_starting_index(input_data['functions'])
			end

			stop = index + 50
			while index < stop
				p 'fetching: '+input_data['functions'][index]['text']+' ('+index.to_s+' / '+stop.to_s+')'
				params = fetch_required_params(input_data['functions'][index]['text'])
				final_data['functions'][index] = input_data['functions'][index]
				final_data['functions'][index]['parameters'] = params
				final_data['functions'][index]['fetch_time'] = Time.now.to_i
				index += 1
			end

			File.open(final_file, "w") do |f|
	  		f.write(JSON.pretty_generate(final_data))
			end
		end

		def get_starting_index(arr, by='fetch_time')
			#
			# start with functions that dont
			# have parameters set first
			#
			arr.each_with_index do |fn, i|
				if fn['parameters'].nil?
					return i
				end
			end
			#
			# if none are missing parameters,
			# get the index of the record with
			# minimum fetch_time (stalest)
			#
			return arr.index(arr.min_by{|x| x[by]})
		end

		def fetch_required_params(function_name)
			fn 							= function_name.gsub('_', '-')
			required_params = []

			#
			# fetch page
			#
			begin
				doc = Nokogiri::HTML(open(@fn_url+fn+".php"))
			rescue
				return required_params
			end

			#
			# access and parse definition
			#
			definition = doc.css('.methodsynopsis').to_s.split('[').first

			begin
				required_params = definition.scan(/\$(.*?)\</).flatten
			rescue
			end

			required_params.map!{|x| '$'+x.to_s }

			return required_params
		end
	end


	class Builder

		attr_reader :compile_from_json_map, :compile_from_remote

		def initialize
			@yaml_map 				= YamlMap.new
			@remote_fetcher		= RemoteFetcher.new
		end

		def build_from_yaml_map
			@yaml_map.build
		end

		def build_from_remote
			@remote_fetcher.build
		end
	end
end
