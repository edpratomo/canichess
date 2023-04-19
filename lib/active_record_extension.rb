module ActiveRecordExtension

  extend ActiveSupport::Concern
  
  module ClassMethods
    def transaction_user username, &blk
      quoted_username = connection.quote(username)
      transaction do
        connection.execute('CREATE TEMPORARY TABLE current_app_user(username TEXT) ON COMMIT DROP')
        connection.execute("INSERT INTO current_app_user VALUES (#{quoted_username})")
        blk.call
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecordExtension)
