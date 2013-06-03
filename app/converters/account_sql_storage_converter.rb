# coding: utf-8

module App
  class AccountSqlStorageConverter
    STATUS_MAP = Hash.new { |h, k|
      raise ArgumentError, "Status #{k.inspect} not known"
    }.update(
      active: 1,
      inactive: 2,
      deleted: 3
    ).freeze

    REVERSE_STATUS_MAP = Hash.new { |h, k|
      raise ArgumentError, "Status #{k.inspect} not known"
    }.update(
      Hash[STATUS_MAP.to_a.map(&:reverse)]
    ).freeze

    def from_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:status] = REVERSE_STATUS_MAP[copy[:status]]
      }
    end

    def to_storage(attrs)
      attrs.dup.tap { |copy|
        copy[:status] = STATUS_MAP[copy[:status]]
      }
    end
  end
end
