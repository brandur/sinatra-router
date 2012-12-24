module Sinatra
  class Router
    def initialize(app=nil, *args, &block)
      @app        = app
      @apps       = []
      @conditions = []

      instance_eval(&block) if block
      @routes = build_routing_table
    end

    def call(env)
      if ret = try_route(env["REQUEST_METHOD"], env["PATH_INFO"], env)
        ret
      else
        raise "neither @app nor @run is set" if !@app && !@run

        # if set as middlware, prefer that, otherwise try default run module
        (@app || @run).call(env)
      end
    end

    # specify the default app to run if no other app routes matched
    def run(app)
      raise "@run already set" if @run
      @run = app
    end

    def route(app, *conditions)
      # mix in context based conditions with conditions given by parameter
      @apps << [app, @conditions + conditions]
    end

    # yield to a builder block in which all defined apps will only respond for
    # the given version
    def version(version, &block)
      @conditions = { version: version }
      instance_eval(&block) if block
      @conditions = {}
    end

    protected

    def with_conditions(*args, &block)
      old = @conditions
      @conditions = @conditions + args
      instance_eval(&block) if block
      @conditions = old
    end

    private

    def build_routing_table
      all_routes = {}
      @apps.each do |app, conditions|
        next unless app.respond_to?(:routes)
        app.routes.each do |verb, routes|
          all_routes[verb] ||= []
          all_routes[verb] += routes.map do |pattern, _, _, _|
            [pattern, conditions, app]
          end
        end
      end
      all_routes
    end

    def conditions_match?(conditions, env)
      conditions.each do |condition|
        return false unless condition.call(env)
      end
      true
    end

    def try_route(verb, path, env)
      # see Sinatra's `route!`
      if verb_routes = @routes[verb]
        verb_routes.each do |pattern, conditions, app|
          if match = pattern.match(path) && conditions_match?(conditions, env)
            status, headers, response = app.call(env)

            # if we got a pass, keep trying routes
            return nil if headers["X-Cascade"] == "pass"

            return status, headers, response
          end
        end
      end
      nil
    end
  end
end
