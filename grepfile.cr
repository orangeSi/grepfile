require "admiral"
class ReadsMapPositionStat < Admiral::Command
	define_argument target,
		description: "target file",
		required: true
	define_argument query,
		description: "query file",
		required: true
	define_flag target_column : Int32,
		default: 1_i32,
		description: ""
	define_flag query_column : Int32,
		default: 1_i32,
		description: ""
	define_flag ignore_line_start_with : String,
		default: "#@",
		description: ""
	define_flag delete_header : String,
		default: "",
		description: "delete id first chars"

	define_flag sep_query : String,
		default: "\t",
		description: "query separator, '\\t' or '\\s'"
	define_flag sep_target : String,
		default: "\t",
		description: "target separator, '\\t' or '\\s'"
	define_flag prefix : String,
		default: "grepfile.out",
		description: "prefix of output"

	
	define_help description: "A replace for grep -f(which cost too many memory)"
	define_version "1.0.1"

	COMPILE_TIME = Time.local

	def run
		if ARGV.size == 0
			puts "complie time: #{COMPILE_TIME}"
			app = __FILE__.gsub(/\.cr$/, "")
			puts `#{app} --help`
			exit 1
		end

		query_ids = {} of String => String
		query_ids_num = 0
		ignore_line_start_with = flags.ignore_line_start_with.split(//)
		puts "ignore_line_start_with is #{ignore_line_start_with}"
		ignore = false
		query_name = Path[arguments.query].basename
		target_name = Path[arguments.target].basename

		# read query file
		puts "start read query"
		File.each_line(arguments.query) do |line|
			ignore_line_start_with.each {|e| ignore = true if line.match(/^#{e}/)}
			#puts "qignore #{ignore} for #{line}"
			if ignore
				ignore = false
				next
			end
			next if line.match(/^\s*$/)
			arr = line.split(/#{flags.sep_query}/)
			raise "error: #{arguments.query} only have #{arr.size} column, but --query_column #{flags.query_column}, try to change --query-sep " if flags.query_column  > arr.size
			id = arr[flags.query_column - 1]
			id = id.gsub(/^#{flags.delete_header}/, "") if flags.delete_header != ""
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
			ignore_line_start_with.each {|e| ignore = true if line.match(/^#{e}/)}
			if ignore
				ignore = false
				next
			end
			next if line.match(/^\s*$/)
			arr = line.split(/#{flags.sep_target}/)
			raise "error: #{arguments.target} only have #{arr.size} column, but --target_column #{flags.target_column}, try to change --target-sep " if flags.target_column  > arr.size
			id = arr[flags.target_column - 1]
			id = id.gsub(/^#{flags.delete_header}/, "") if flags.delete_header != ""
			#puts "tid is #{id}"
			unless target_ids.has_key?(id)
				target_ids_num = target_ids_num + 1
				target_ids[id] = ""
			end
		end

		puts "start get query uniq"
		core_out = File.open("#{flags.prefix}.#{target_name}.#{query_name}.core.hold", "w")
		core_number = 0
		query_ids_uniq_num = 0
		qout = File.open("#{arguments.query}.uniq.hold.in#{flags.query_column}col.#{flags.prefix}", "w")
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
		tout = File.open("#{arguments.target}.uniq.hold.in#{flags.target_column}col.#{flags.prefix}", "w")
		target_ids.each do |key, value|
			unless query_ids.has_key?(key)
				tout.puts(key) 
				target_ids_uniq_num = target_ids_uniq_num + 1
			end
		end
		tout.close

		puts "\ncore_num\t#{core_number}"
		puts "target_ids_num\t#{target_ids_num}\tuniq\t#{target_ids_uniq_num}"
		puts "query_ids_num\t#{query_ids_num}\tuniq\t#{query_ids_uniq_num}"

	end
end

ReadsMapPositionStat.run
