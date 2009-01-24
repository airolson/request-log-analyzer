module RequestLogAnalyzer::Tracker
  
  # Catagorize requests by frequency.
  # Count and analyze requests for a specific attribute 
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:title</tt> Title do be displayed above the report.
  # * <tt>:category</tt> Proc that handles the request categorization.
  # * <tt>:amount</tt> The amount of lines in the report
  #
  # The items in the update request hash are set during the creation of the Duration tracker.
  #
  # Example output:
  #  HTTP methods
  #  ----------------------------------------------------------------------
  #  GET    |  22248 hits (46.2%) |░░░░░░░░░░░░░░░░░
  #  PUT    |  13685 hits (28.4%) |░░░░░░░░░░░
  #  POST   |  11662 hits (24.2%) |░░░░░░░░░
  #  DELETE |    512 hits (1.1%)  |
  class Frequency < Base

    attr_reader :categories

    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:category]
      @categories = {}
      if options[:all_categories].kind_of?(Enumerable)
        options[:all_categories].each { |cat| @categories[cat] = 0 }
      end
    end
            
    def update(request)
      cat = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
      if !cat.nil? || options[:nils]
        @categories[cat] ||= 0
        @categories[cat] += 1
      end
    end

    def report(output)
      output.title(options[:title]) if options[:title]
    
      if @categories.empty?
        output << "None found.\n" 
      else
        sorted_categories = @categories.sort { |a, b| b[1] <=> a[1] }
        total_hits        = sorted_categories.inject(0) { |carry, item| carry + item[1] }
        sorted_categories = sorted_categories.slice(0...options[:amount]) if options[:amount]

        output.table({:align => :left}, {:align => :right }, {:align => :right}, {:type => :ratio, :width => :rest}) do |rows|        
          sorted_categories.each do |(cat, count)|
            rows << [cat, "#{count} hits", '%0.1f%%' % ((count.to_f / total_hits.to_f) * 100.0), (count.to_f / total_hits.to_f)]
          end
        end

      end
    end
  end
end
