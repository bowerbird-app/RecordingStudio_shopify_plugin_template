# frozen_string_literal: true

module RecordingStudioShopifyPluginTemplate
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioShopifyPluginTemplate

    class << self
      def apply_model_extensions(target)
        apply_extensions(target, extensions_for(:model, extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target, extensions_for(:controller, extension_keys_for(target)))
      end

      private

      def extensions_for(kind, names)
        hooks = RecordingStudioShopifyPluginTemplate.configuration.hooks
        Array(names).flat_map do |name|
          if kind == :model
            hooks.model_extensions_for(name)
          else
            hooks.controller_extensions_for(name)
          end
        end
      end

      def apply_extensions(target, extensions)
        return unless target

        applied_ivar = :@recording_studio_shopify_plugin_template_applied_extensions
        applied = target.instance_variable_get(applied_ivar) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(applied_ivar, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    initializer "recording_studio_shopify_plugin_template.before_initialize",
                before: "recording_studio_shopify_plugin_template.load_config" do |_app|
      RecordingStudioShopifyPluginTemplate.configuration.hooks.run(:before_initialize, self)
    end

    # rubocop:disable Metrics/BlockLength
    initializer "recording_studio_shopify_plugin_template.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = begin
            app.config_for(:recording_studio_shopify_plugin_template)
          rescue StandardError
            nil
          end
          RecordingStudioShopifyPluginTemplate.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError
          nil
        end
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_shopify_plugin_template)
        xcfg = app.config.x.recording_studio_shopify_plugin_template
        if xcfg.respond_to?(:to_h)
          RecordingStudioShopifyPluginTemplate.configuration.merge!(xcfg.to_h)
        else
          begin
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioShopifyPluginTemplate.configuration.merge!(hash) if hash&.any?
          rescue StandardError
            nil
          end
        end
      end

      hooks = RecordingStudioShopifyPluginTemplate.configuration.hooks
      config = RecordingStudioShopifyPluginTemplate.configuration
      hooks.run(:on_configuration, config)
    end
    # rubocop:enable Metrics/BlockLength

    initializer "recording_studio_shopify_plugin_template.after_initialize",
                after: "recording_studio_shopify_plugin_template.load_config" do |_app|
      RecordingStudioShopifyPluginTemplate.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_shopify_plugin_template.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioShopifyPluginTemplate::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_shopify_plugin_template.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioShopifyPluginTemplate::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
