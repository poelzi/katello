Katello::RepositoryTypeManager.register(::Katello::Repository::YUM_TYPE) do
  service_class Katello::Pulp::Repository::Yum
  prevent_unneeded_metadata_publish

  content_type Katello::Rpm, :priority => 1, :pulp2_service_class => ::Katello::Pulp::Rpm
  content_type Katello::Erratum, :priority => 2, :pulp2_service_class => ::Katello::Pulp::Erratum
  content_type Katello::ModuleStream, :priority => 3, :pulp2_service_class => ::Katello::Pulp::ModuleStream
  content_type Katello::PackageGroup, :pulp2_service_class => ::Katello::Pulp::PackageGroup
  content_type Katello::YumMetadataFile, :pulp2_service_class => ::Katello::Pulp::YumMetadataFile
  content_type Katello::Srpm, :pulp2_service_class => ::Katello::Pulp::Srpm

  index_additional_data { |repo, target_repo = nil| repo.import_distribution_data(target_repo) }
end
