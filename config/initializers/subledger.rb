module PnP
  class ApiError < RocketPants::Error
    http_status :bad_request
    error_name :pnp_api_error
  end

  module RocketPantsIntegration
    extend ActiveSupport::Concern

    included do
      def self.map_api_error(clazz)
        map_error! clazz do |exception|
          ApiError.new exception.message
        end
      end

      # map store api errors
      #map_api_error Subledger::Store::Api::Errors::BadRequest
      #map_api_error Subledger::Store::Api::Errors::Unauthorized
      #map_api_error Subledger::Store::Api::Errors::Forbidden
      #map_api_error Subledger::Store::Api::Errors::NotFound
      #map_api_error Subledger::Store::Api::Errors::NotAcceptable
      #map_api_error Subledger::Store::Api::Errors::Conflict
      #map_api_error Subledger::Store::Api::Errors::UnprocessableEntity
      #map_api_error Subledger::Store::Api::Errors::InternalServerError
      #map_api_error Subledger::Store::Api::Errors::NotImplemented
      #map_api_error Subledger::Store::Api::Errors::BadGateway
      #map_api_error Subledger::Store::Api::Errors::ServiceUnavailable
      #map_api_error Subledger::Store::Api::Errors::HttpError
      #map_api_error Subledger::Store::Api::Errors::ServerNotAvailable

      # map client error
      map_api_error Subledger::Interface::ClientError

      # map domain errors
      map_api_error Subledger::Domain::CategoryError
      map_api_error Subledger::Domain::ControlError
      map_api_error Subledger::Domain::AccountError
      map_api_error Subledger::Domain::OrgError
      map_api_error Subledger::Domain::BookError
      map_api_error Subledger::Domain::KeyError
      map_api_error Subledger::Domain::BalanceError
      map_api_error Subledger::Domain::ValueError
      map_api_error Subledger::Domain::JournalEntryError
      map_api_error Subledger::Domain::LineError
      map_api_error Subledger::Domain::PostedLineError
      map_api_error Subledger::Domain::ReportError
      map_api_error Subledger::Domain::IdentityError
      map_api_error Subledger::Domain::ReportRenderingError
      map_api_error Subledger::Domain::ActivatableError
      map_api_error Subledger::Domain::ArchivableError
      map_api_error Subledger::Domain::AttributableError
      map_api_error Subledger::Domain::CollectableError
      map_api_error Subledger::Domain::CreatableError
      map_api_error Subledger::Domain::DescribableError
      map_api_error Subledger::Domain::DescribableReportRenderingError
      map_api_error Subledger::Domain::IdentifiableError
      map_api_error Subledger::Domain::PostableError
      map_api_error Subledger::Domain::ProgressableError
      map_api_error Subledger::Domain::ReadableError
      map_api_error Subledger::Domain::RestableError
      map_api_error Subledger::Domain::StorableError
      map_api_error Subledger::Domain::TimeableError
      map_api_error Subledger::Domain::UpdatableError
      map_api_error Subledger::Domain::VersionableError

      # map store error
      map_api_error Subledger::Store::ActivateError
      map_api_error Subledger::Store::ArchiveError
      map_api_error Subledger::Store::AttachError
      map_api_error Subledger::Store::BalanceError
      map_api_error Subledger::Store::CategoryError
      map_api_error Subledger::Store::CollectError
      map_api_error Subledger::Store::CreateError
      map_api_error Subledger::Store::CreateLineError
      map_api_error Subledger::Store::DeleteError
      map_api_error Subledger::Store::DetachError
      map_api_error Subledger::Store::FirstAndLastLineError
      map_api_error Subledger::Store::PostError
      map_api_error Subledger::Store::ProgressError
      map_api_error Subledger::Store::ReadError
      map_api_error Subledger::Store::ReportError
      map_api_error Subledger::Store::UpdateError
      map_api_error Subledger::Store::UpdateNotFoundError
      map_api_error Subledger::Store::UpdateConflictError
      map_api_error Subledger::Store::BucketValidatorError

      # other errors
      map_api_error SubledgerError
      map_api_error Subledger::DateError
    end
  end
end

# add methods required for active_model_serializer to subledger domains
Subledger::Domain.send(:define_method, 'read_attribute_for_serialization') do |n|
    self.attributes[n.to_sym]
end

Subledger::Domain::Value.send(:define_method, 'read_attribute_for_serialization') do |n|
    self.rest_hash[n.to_s]
end

# map subledger errors to rocketpants
RocketPants::Base.send :include, PnP::RocketPantsIntegration
