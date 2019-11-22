require "admiral"
class GrepFile < Admiral::Command
	define_argument target,
		description: "target file",
		required: true
	define_argument query,
		description: "query file",
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

	define_flag sep_query : String,
		default: "\t",
		description: "query separator, '\\t' or '\\s'"
	define_flag sep_target : String,
		default: "\t",
		description: "target separator, '\\t' or '\\s'"
	define_flag prefix : String,
		default: "myth",
		description: "prefix of output"

	
	define_help description: "A replace for grep -f(which cost too many memory)"
	define_version "1.0.2"

	COMPILE_TIME = Time.local

	def run
		if ARGV.size == 0
			#puts "complie time: #{COMPILE_TIME}"
			#app = __FILE__.gsub(/\.cr$/, "")
			#puts `#{app} --help`
			#exit 1
			GrepFile.run "--help"
		end

		query_ids = {} of String => String
		query_ids_num = 0
		ignore_line_mathed_by = flags.ignore_line_mathed_by
		puts "--ignore-line-mathed-by  #{ignore_line_mathed_by}"
		puts "--delete-chars-from-column #{flags.delete_chars_from_column}" if flags.delete_chars_from_column != ""
		ignore = false
		query_name = Path[arguments.query].basename
		target_name = Path[arguments.target].basename

		# read query file
		puts "start read query"
		File.each_line(arguments.query) do |line|
			next if ignore_line_mathed_by !="" && line.match(/#{ignore_line_mathed_by}/)
			next if line.match(/^\s*$/)
			arr = line.split(/#{flags.sep_query}/)
			raise "error: #{arguments.query} only have #{arr.size} column, but --column_query #{flags.column_query}, try to change --query-sep " if flags.column_query  > arr.size
			id = arr[flags.column_query - 1]
			id = id.gsub(/#{flags.delete_chars_from_column}/, "") if flags.delete_chars_from_column != ""
			#puts "qid is #{id}"
			unless query_ids.has_key?(id)
				query_ids_num = query_ids_num +1
				query_ids[id] = "" 
			end
		end


		puts "start read target"
		## read target file
		target_ids = {} of String => String
		target_ids_num = 0
		File.each_line(arguments.target) do |line|
			next if ignore_line_mathed_by != "" && line.match(/#{ignore_line_mathed_by}/)
			next if line.match(/^\s*$/)
			arr = line.split(/#{flags.sep_target}/)
			raise "error: #{arguments.target} only have #{arr.size} column, but --column_target #{flags.column_target}, try to change --target-sep " if flags.column_target  > arr.size
			id = arr[flags.column_target - 1]
			id = id.gsub(/#{flags.delete_chars_from_column}/, "") if flags.delete_chars_from_column != ""
			#puts "tid is #{id}"
			unless target_ids.has_key?(id)
				target_ids_num = target_ids_num + 1
				target_ids[id] = ""
			end
		end

		puts "start get query uniq"
		core_out = File.open("#{flags.prefix}.coreid.list", "w")
		core_number = 0
		query_ids_uniq_num = 0
		qout = File.open("#{flags.prefix}.q.column#{flags.column_query}.uniqid.list", "w")
		query_ids.each do |key, value|
			unless target_ids.has_key?(key)
				qout.puts(key) 
				query_ids_uniq_num = query_ids_uniq_num + 1
			else
				core_out.puts(key)
				core_number = core_number + 1
			end
		end
		qout.close
		core_out.close

		puts "start get target uniq"
		target_ids_uniq_num = 0
		tout = File.open("#{flags.prefix}.t.column#{flags.column_target}.uniqid.list", "w")
		target_ids.each do |key, value|
			unless query_ids.has_key?(key)
				tout.puts(key) 
				target_ids_uniq_num = target_ids_uniq_num + 1
			end
		end
		tout.close
		raise "error: core_number+target_ids_uniq_num != target_ids_num: #{core_number}+#{target_ids_uniq_num} != #{target_ids_num}\n" if core_number+target_ids_uniq_num != target_ids_num
		raise "error: core_number+query_ids_uniq_num != query_ids_num: #{core_number}+#{query_ids_uniq_num} != #{query_ids_num}\n" if core_number+query_ids_uniq_num != query_ids_num

		out_stat = "db\tcore_number\tuniq_number\tcore_number_percent\tuniq_number_percent\ttotal_number\n"
		out_stat += "#{target_name}\t#{core_number}\t#{target_ids_uniq_num}\t#{core_number.to_f/target_ids_num}\t#{target_ids_uniq_num.to_f/target_ids_num}\t#{target_ids_num}\n"
		out_stat += "#{query_name}\t#{core_number}\t#{query_ids_uniq_num}\t#{core_number.to_f/query_ids_num}\t#{query_ids_uniq_num.to_f/query_ids_num}\t#{query_ids_num}\n"
		puts "#{out_stat}\n"
		File.write("#{flags.prefix}.diff.stat.txt", out_stat)
	end
end

GrepFile.run
