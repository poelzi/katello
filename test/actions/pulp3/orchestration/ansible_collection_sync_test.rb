require 'katello_test_helper'

module ::Actions::Pulp3
  class AnsibleCollectionSyncTest < ActiveSupport::TestCase
    include Katello::Pulp3Support

    def setup
      @master = FactoryBot.create(:smart_proxy, :default_smart_proxy, :with_pulp3)
      @repo = katello_repositories(:pulp3_ansible_collection_1)
      create_repo(@repo, @master)
      ForemanTasks.sync_task(
          ::Actions::Katello::Repository::MetadataGenerate, @repo,
          repository_creation: true)

      repository_reference = Katello::Pulp3::RepositoryReference.find_by(
          :root_repository_id => @repo.root.id,
          :content_view_id => @repo.content_view.id)

      assert repository_reference
      refute_empty repository_reference.repository_href
      refute_empty Katello::Pulp3::DistributionReference.where(
          root_repository_id: @repo.root.id)
      @repo_version_href = @repo.version_href
    end

    def teardown
      ForemanTasks.sync_task(
          ::Actions::Pulp3::Orchestration::Repository::Delete, @repo, @master)
      @repo.reload
    end

    def test_sync
      sync_args = {:smart_proxy_id => @master.id, :repo_id => @repo.id}
      ForemanTasks.sync_task(::Actions::Pulp3::Orchestration::Repository::Sync, @repo, @master, sync_args)
      @repo.reload
      refute_equal @repo.version_href, @repo_version_href
      repository_reference = Katello::Pulp3::RepositoryReference.find_by(
          :root_repository_id => @repo.root.id,
          :content_view_id => @repo.content_view.id)

      assert_equal repository_reference.repository_href + "versions/2/", @repo.version_href
    end

    def test_sync_mirror_false
      sync_args = {:smart_proxy_id => @master.id, :repo_id => @repo.id}
      ForemanTasks.sync_task(::Actions::Pulp3::Orchestration::Repository::Sync, @repo, @master, sync_args)
      @repo.reload
      repository_reference = Katello::Pulp3::RepositoryReference.find_by(
          :root_repository_id => @repo.root.id,
          :content_view_id => @repo.content_view.id)

      assert_equal repository_reference.repository_href + "versions/2/", @repo.version_href
      @repo.index_content
      pre_count_content = ::Katello::RepositoryAnsibleCollection.where(:repository_id => @repo.id).count
      @repo.root.update_attributes!(:url => 'https://galaxy.ansible.com/api/v2/collections/testing/k8s_demo_collection/?version=0.0.3', :mirror_on_sync => false)

      ForemanTasks.sync_task(
          ::Actions::Pulp3::Orchestration::Repository::Update,
          @repo,
          @master)

      ForemanTasks.sync_task(::Actions::Pulp3::Orchestration::Repository::Sync, @repo, @master, sync_args)
      @repo.reload
      @repo.index_content
      post_count_content = ::Katello::RepositoryAnsibleCollection.where(:repository_id => @repo.id).count
      repository_reference = Katello::Pulp3::RepositoryReference.find_by(
          :root_repository_id => @repo.root.id,
          :content_view_id => @repo.content_view.id)

      assert_equal repository_reference.repository_href + "versions/3/", @repo.version_href
      assert_equal pre_count_content + 1, post_count_content
    end

    def test_sync_mirror_true
      sync_args = {:smart_proxy_id => @master.id, :repo_id => @repo.id}
      ForemanTasks.sync_task(::Actions::Pulp3::Orchestration::Repository::Sync, @repo, @master, sync_args)
      @repo.reload
      @repo.index_content
      pre_count_content = ::Katello::RepositoryAnsibleCollection.where(:repository_id => @repo.id).count
      @repo.root.update_attributes(:ansible_collection_whitelist => 'newswangerd.collection_demo')

      ForemanTasks.sync_task(
          ::Actions::Pulp3::Orchestration::Repository::Update,
          @repo,
          @master)

      ForemanTasks.sync_task(::Actions::Pulp3::Orchestration::Repository::Sync, @repo, @master, sync_args)
      @repo.reload
      @repo.index_content
      post_count_content = ::Katello::RepositoryAnsibleCollection.where(:repository_id => @repo.id).count
      assert_equal pre_count_content, post_count_content
    end
  end
end