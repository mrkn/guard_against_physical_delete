module GuardAgainstPhysicalDelete
  module Base
    def self.included(obj)
      obj.extend ClassMethods
      obj.class_eval do
        class_attribute :logical_delete_column
        self.logical_delete_column = :deleted_at
      end
    end

    module ClassMethods
      def physical_delete(&block)
        Thread.current['physical_delete'] ||= Hash.new { |h,k| h[k] = 0 }
        Thread.current['physical_delete'][self.name] += 1
        yield
      ensure
        Thread.current['physical_delete'][self.name] -= 1
      end

      def is_logical_delete?
        return true if self.column_names.include?(logical_delete_column.to_s)
        return false
      end

      def delete_permitted?
        Thread.current['physical_delete'] ||= Hash.new { |h,k| h[k] = 0 }
        return true unless Thread.current['physical_delete'][self.name].zero?
        return false if is_logical_delete?
        return true
      end
    end
  end
end
