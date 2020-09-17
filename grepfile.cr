require "admiral"
require "gzip"

class GrepFile < Admiral::Command
	define_argument target,
		description: "target file, support .gz file or stdin(by -)",
		required: true
	define_argument query,
		description: "query file, support .gz file or stdin(by -)",
		required: true
	define_flag column_target : Int32,
		default: 1_i32,
		description: ""
	define_flag column_query : Int32,
		default: 1_i32,
		description: ""
	define_flag ignore_line_mathed_by : String,
		default: "^[#@]",
		description: "if id start with # or @, will remove # or @, support regex syntax"
	define_flag delete_chars_from_column : String,
		default: "^>",
		description: "delete id first chars, support regex syntax"
	define_flag invert_match : Int32,
		default: 0_i32,
		description: "Invert the sense of matching, to select non-matching lines"
	define_flag sep_query : String,
		default: "\t",
		description: "query separator, '\\t' or '\\s'"
	define_flag exact_match : Int32,
		default: 1_i32,
		description: "if >=1, mean equal totally else mean macth"
	define_flag sep_target : String,
		default: "\t",
		description: "target separator, '\\t' or '\\s'"

	
	define_help description: "A replace for $ grep -f (which cost too many memory and time) in Linux"
	define_version "1.0.4"

	COMPILE_TIME = Time.local

	def run
		if ARGV.size == 0
			#puts "complie time: #{COMPILE_TIME}"
			#app = __FILE__.gsub(/\.cr$/, "")
			#puts `#{app} --help`
			#exit 1
			puts "Contact: https://github.com/orangeSi/grepfile/issues"
			GrepFile.run "--help"
		end

		query_ids = {} of String => String
		ignore_line_mathed_by = flags.ignore_line_mathed_by
		ignore = false
		query_name = Path[arguments.query].basename
		target_name = Path[arguments.target].basename

		
		# read query file
		#puts "arguments.query is #{arguments.query}"
		if arguments.query == "-"
			STDIN.each_line do |line|
				query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by=flags.ignore_line_mathed_by, sep_query=flags.sep_query, query=arguments.query, delete_chars_from_column=flags.delete_chars_from_column)
			end
		elsif arguments.query.match(/.*\.gz$/) # gzip file
			Gzip::Reader.open(arguments.query) do |gfile|
				gfile.each_line do |line|
					query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by=flags.ignore_line_mathed_by, sep_query=flags.sep_query, query=arguments.query, delete_chars_from_column=flags.delete_chars_from_column)
				end
			end
		else # not gzip file
			File.each_line(arguments.query) do |line|
				query_ids = read_query_file(line, flags.column_query, query_ids, ignore_line_mathed_by=flags.ignore_line_mathed_by, sep_query=flags.sep_query, query=arguments.query, delete_chars_from_column=flags.delete_chars_from_column)
			end
		end	


		## read target file
		target_ids = {} of String => String
		target_ids_num = 0
		File.each_line(arguments.target) do |line|
			next if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
			next if line.match(/^\s*$/)
			arr = line.split(/#{flags.sep_target}/)
			raise "error: #{arguments.target} only have #{arr.size} column in line #{line}, but --column_target #{flags.column_target}, try to change --sep_target for line: #{arr}\n" if flags.column_target  > arr.size
			id = arr[flags.column_target - 1]
			id = id.gsub(/#{flags.delete_chars_from_column}/, "") if flags.delete_chars_from_column != ""
			if flags.invert_match == 0
				if flags.exact_match >=1
					if query_ids.has_key?(id)
						puts "#{line}"		
					end
				else
					query_ids.each_key do |k|
						if id=~ /#{k}/
							puts "#{line}"
							break
						end
					end
				end
				
			else # flags.invert_match >=1
				if flags.exact_match >=1
					if !query_ids.has_key?(id)
						puts "#{line}"		
					end
				else
					#raise "error: --invert_match #{flags.invert_match} not support --exact_match=#{flags.exact_match}"
					matched_flag = 0
					query_ids.each_key do |k|
						if id=~ /#{k}/
							matched_flag = 1
							break
						end
					end
					if matched_flag == 0
						puts "#{line}"			
					end
					
				end
			end
		end

	end
	def read_query_file(line : String, column_query : Int32, query_ids : Hash(String, String), ignore_line_mathed_by : String = "", sep_query : String = "\t", query : String = "", delete_chars_from_column : String = "")
		return query_ids if ignore_line_mathed_by !="" && line.match(/#{ignore_line_mathed_by}/)
		return query_ids if line.match(/^\s*$/)
		arr = line.split(/#{sep_query}/)
		raise "error: query #{query} only have #{arr.size} columns, but --column_query #{column_query}, try to change --sep_query for line: #{arr}\n" if column_query  > arr.size
		id = arr[column_query - 1]
		id = id.gsub(/#{delete_chars_from_column}/, "") if delete_chars_from_column != ""
		unless query_ids.has_key?(id)
			query_ids[id] = "" 
		end
		return query_ids	
	end
end

GrepFile.run
