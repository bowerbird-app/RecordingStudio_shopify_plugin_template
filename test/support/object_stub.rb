# frozen_string_literal: true

# Minitest 6 removed minitest/mock (and Object#stub). Keep a small test-only
# replacement so existing `obj.stub :name, replacement { ... }` calls still run.
module ObjectStub
  def stub(name, val_or_callable, *)
    name = name.to_sym
    metaclass = singleton_class
    backup = :"_minitest_stub__#{name}"
    invented = ObjectStub.backup_method!(metaclass, name, backup)
    ObjectStub.install_stub!(metaclass, name, val_or_callable)
    yield
  ensure
    ObjectStub.restore_method!(metaclass, name, backup, invented: invented)
  end

  def self.method_on?(metaclass, name)
    metaclass.method_defined?(name) || metaclass.private_method_defined?(name)
  end

  def self.backup_method!(metaclass, name, backup)
    invented = !method_on?(metaclass, name)
    metaclass.define_method(name) { |*| } if invented
    metaclass.alias_method backup, name
    invented
  end

  def self.install_stub!(metaclass, name, val_or_callable)
    if val_or_callable.respond_to?(:call)
      metaclass.define_method(name) do |*args, **kwargs, &block|
        val_or_callable.call(*args, **kwargs, &block)
      end
    else
      metaclass.define_method(name) { |*| val_or_callable }
    end
  end

  def self.restore_method!(metaclass, name, backup, invented:)
    metaclass.undef_method(name) if method_on?(metaclass, name)
    return unless method_on?(metaclass, backup)

    metaclass.alias_method name, backup unless invented
    metaclass.undef_method backup
  end
end

Object.prepend(ObjectStub)
