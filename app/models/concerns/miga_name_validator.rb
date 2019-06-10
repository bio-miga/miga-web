require 'miga'

class MigaNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value.miga_name == value
      record.errors.add(attribute,
        'isn\'t a MiGA name (only alphanumerics and underscore)')
    end
  end
end
