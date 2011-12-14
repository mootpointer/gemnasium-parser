require "bundler"
require "gemnasium/parser/patterns"

module Gemnasium
  module Parser
    class Gemfile
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def dependencies
        @dependencies ||= [].tap do |deps|
          gem_matches.each do |match|
            dep = dependency(match)
            deps << dep if dep
          end
        end
      end

      def gemspec
        @gemspec = if gemspec_match
          opts = Patterns.options(gemspec_match["opts"])
          path = opts["path"]
          name = opts["name"] || "*"
          File.join(*[path, "#{name}.gemspec"].compact)
        end
      end

      def gemspec?
        !!gemspec
      end

      private
        def gem_matches
          @gem_matches ||= matches(Patterns::GEM_CALL)
        end

        def matches(pattern)
          [].tap{|m| content.scan(pattern){ m << Regexp.last_match } }
        end

        def dependency(match)
          opts = Patterns.options(match["opts"])
          return nil if opts["git"] || opts["path"]
          name = match["name"]
          reqs = [match["req1"], match["req2"]].compact
          opts["group"] ||= groups(match)
          Bundler::Dependency.new(name, reqs, opts)
        end

        def groups(gem_match)
          call = gem_match.begin(0)
          match = group_matches.detect do |group_match|
            (group_match.begin(:blk)..group_match.end(:blk)).cover?(call)
          end
          match && Patterns.values(match[:grps])
        end

        def group_matches
          @group_matches ||= matches(Patterns::GROUP_CALL)
        end

        def gemspec_match
          return @gemspec_match if defined?(@gemspec_match)
          @gemspec_match = content.match(Patterns::GEMSPEC_CALL)
        end

        def bundler
          @bundler ||= Bundler::Dsl.new
        end
    end
  end
end
