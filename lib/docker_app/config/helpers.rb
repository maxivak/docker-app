# encoding: utf-8
require 'ostruct'

module DockerApp
  module Config
    module Helpers

      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods

        def defaults
          @defaults ||= Config::Defaults.new

          if block_given?
            yield @defaults
          else
            @defaults
          end
        end

        # Used only within the specs
        def clear_defaults!
          defaults.reset!
        end

        def deprecations
          @deprecations ||= {}
        end

        protected



      end # ClassMethods

      private

      ##
      # Sets any pre-configured default values.
      # If a default value was set for an invalid accessor,
      # this will raise a NameError.
      def load_defaults!
        self.class.defaults._attributes.each do |name|
          val = self.class.defaults.send(name)
          val = val.dup rescue val
          send(:"#{ name }=", val)
        end
      end

      ##
      # Check missing methods for deprecated attribute accessors.
      #
      # If a value is set on an accessor that has been deprecated
      # using #attr_deprecate, a warning will be issued and any
      # :action (Proc) specified will be called with a reference to
      # the class instance and the value set on the deprecated accessor.
      # See #attr_deprecate and #log_deprecation_warning
      #
      # Note that OpenStruct (used for setting defaults) does not allow
      # multiple arguments when assigning values for members.
      # So, we won't allow it here either, even though an attr_accessor
      # will accept and convert them into an Array. Therefore, setting
      # an option value using multiple values, whether as a default or
      # directly on the class' accessor, should not be supported.
      # i.e. if an option will accept being set as an Array, then it
      # should be explicitly set as such. e.g. option = [val1, val2]
      #
      def method_missing(name, *args)
        if method = name.to_s.chomp!('=')
          if (len = args.count) != 1
            raise ArgumentError,
                  "wrong number of arguments (#{ len } for 1)", caller(1)
          end
        end

        super
      end

    end # Helpers

    # Store for pre-configured defaults.
    class Defaults < OpenStruct
      # Returns an Array of all attribute method names
      # that default values were set for.
      def _attributes
        @table.keys
      end

      # Used only within the specs
      def reset!
        @table.clear
      end
    end

  end
end
