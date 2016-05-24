require 'avro_turf/messaging'

module Avromatic
  module Model

    # This concern adds support for serialization based on AvroTurf::Messaging.
    # This serialization leverages a schema registry to prefix encoded values
    # with an id for the schema.
    module Messaging
      extend ActiveSupport::Concern

      delegate :messaging, to: :Avromatic

      module Encode
        def avro_message_value
          messaging.encode(
            value_attributes_for_avro,
            schema_name: value_avro_schema.fullname
          )
        end

        def avro_message_key
          raise 'Model has no key schema' unless key_avro_schema
          messaging.encode(
            key_attributes_for_avro,
            schema_name: key_avro_schema.fullname
          )
        end
      end
      include Encode

      # This module provides methods to deserialize an Avro-encoded value and
      # an optional Avro-encoded key as a new model instance.
      module Decode

        # If two arguments are specified then the first is interpreted as the
        # message key and the second is the message value. If there is only one
        # arg then it is used as the message value.
        def deserialize(*args)
          message_key, message_value = args.size > 1 ? args : [nil, args.first]
          key_attributes = message_key && messaging.decode(message_key, schema_name: key_avro_schema.fullname)
          value_attributes = messaging.decode(message_value, schema_name: avro_schema.fullname)

          new(value_attributes.merge!(key_attributes || {}))
        end
      end

      module ClassMethods
        # The messaging object acts as an intermediary talking to the schema
        # registry and using returned/specified schemas to decode/encode.
        delegate :messaging, to: :Avromatic

        include Decode
      end
    end
  end
end