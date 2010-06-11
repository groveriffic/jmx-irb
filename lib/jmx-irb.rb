require 'jmx4r'

$jmx_irb_eval_binding = binding()

module JMXIRB

    class << self
    
        def enable(name = 'DefaultEvalContext')
            @name = name

            unregister if is_registered?
            register
            at_exit do
                unregister if is_registered?
            end
        end

        private

        def mbean_server
            @mbean_server ||= java.lang.management.ManagementFactory.getPlatformMBeanServer()
        end

        def mbean
            @mbean ||= EvalMBean.new
        end

        def obj_name
            @obj_name ||= javax.management.ObjectName.new('org.jruby.jmx-irb', 'type', @name)
        end

        def is_registered?
            mbean_server.isRegistered(obj_name)
        end

        def register
            mbean_server.registerMBean(mbean, obj_name)
        end

        def unregister
            mbean_server.unregisterMBean(obj_name)
        end

    end

    class EvalMBean < JMX::DynamicMBean
        operation "Evaluate Code"
        parameter :string, "code", "JRuby Code"
        returns :string

        def evaluate(code)
            begin
                result = Kernel.eval(code, $jmx_irb_eval_binding)
                return result.inspect
            rescue Exception => e
                return [e.inspect, e.backtrace].flatten.join("\n")
            end
        end
    end

    class Session
        def initialize(args={})
            @prompt = args[:host] && "#{args[:host]}:#{args[:port]} > " || "#{args[:url]} > "
            JMX::MBean.establish_connection(args)
            contexts = JMX::MBean.find_all_by_name('org.jruby.jmx-irb:type=*')
            if contexts.size == 0 then
                raise "Remote EvalMBean not available"
            elsif contexts.size == 1 then
                @context = contexts.first
            else
                raise "More than one remote EvalMBean running.  Context selection not supported... yet"
            end

            main
        end

        private

        def main
            while STDOUT.write(@prompt) and code = STDIN.gets
                break if code =~ /^exit\s*$/
                result = evaluate(code)
                STDOUT.puts '=> ' + result
            end
        end

        def evaluate(code)
            @context.evaluate(code)
        end
    end
end

