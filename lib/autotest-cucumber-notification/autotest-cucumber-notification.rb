# Usage:: see README
module AutotestCucumberNotification

  # Notifier configuration helpers and defaults.
  class Config

    class << self
      attr_reader :images_directory
      attr_accessor :success_image, :fail_image, :pending_image, :undefined_image, :expiration_in_seconds,
        :failure, :success, :pending, :undefined, :fade_timeout

      def images_directory=(path)
        @images_directory = File.expand_path(path)
        @success_image = "#{@images_directory}/pass.png"
        @fail_image = "#{@images_directory}/fail.png"
        @pending_image = "#{@images_directory}/pending.png"
        @undefined_image = "#{@images_directory}/undefined.png"
      end
    end

    self.images_directory = File.expand_path('../../images', File.dirname(__FILE__))
    self.fade_timeout = 5000
    self.failure = "Features Failure"
    self.success = "Features Success"
    self.pending = "Features Pending"
    self.undefined = "Features Undefined"

  end

  Autotest.add_hook :ran_features do |at|
    result = at.results.is_a?(String) ? at.results : at.results.to_s

    if result
      @scenarios = result[/(\d+) scenarios?/,1].to_i
      @steps = result[/(\d+) steps?/,1].to_i
      @scenario_stats = Hash.new
      @step_stats = Hash.new

      %w{ failed skipped passed pending undefined }.each do |x|
        @scenario_stats.merge!({ "#{x}" => result[/\d+ scenarios?.*?(\d+) #{x}.*\)/,1].to_i })
        @step_stats.merge!({ "#{x}" => result[/\d+ steps?.*?(\d+) #{x}.*\)/,1].to_i })
      end

      if @scenario_stats["failed"] > 0 || @step_stats["failed"] > 0
        notify Config.failure, assemble_msg(@scenarios,@steps,@scenario_stats,@step_stats), Config.fail_image
      elsif @scenario_stats["pending"] > 0 || @step_stats["pending"] > 0
        notify Config.pending, assemble_msg(@scenarios,@steps,@scenario_stats,@step_stats), Config.pending_image
      elsif @scenario_stats["undefined"] > 0 || @step_stats["undefined"] > 0
        notify Config.undefined, assemble_msg(@scenarios,@steps,@scenario_stats,@step_stats), Config.undefined_image
      elsif @scenario_stats["passed"] > 0 && @step_stats["passed"] > 0
        notify Config.success, assemble_msg(@scenarios,@steps,@scenario_stats,@step_stats), Config.success_image
      else
        notify Config.failure, "Errors Ecountered", Config.fail_image
      end
    end
  end

  class << self

    def notify(title, msg, img = Config.success_image)
      system "notify-send -i #{img} '#{title}' '#{msg}' -t #{Config.fade_timeout}"
    end

    def pluralize(text, number)
      "#{number} #{text}#{'s' if number != 1}"
    end

    def assemble_msg(scenarios, steps, scenario_stats = {}, step_stats = {})
      msg = ""
      if scenarios > 0
        msg += "#{pluralize('scenario',scenarios)}"
        msg += "\n#{stat_string(scenario_stats)}"
        msg += "\n\n" if steps > 0
      end
      if steps > 0
        msg += "#{pluralize('step',steps)}"
        msg += "\n#{stat_string(step_stats)}"
      end
      return msg
    end

    def stat_string(hash)
      stat_str = "("
      hash.each do |key,value|
        if value > 0
          stat_str += "#{value} #{key},"
        end
      end
      stat_str += ")"
      stat_str.gsub!(",\)",")")
    end
  end

end
