module Sufia::GenericFile
  # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
  module Actions
    def self.create_metadata(generic_file, user, batch_id)

      generic_file.apply_depositor_metadata(user.user_key)
      generic_file.date_uploaded = Date.today
      generic_file.date_modified = Date.today
      generic_file.creator = user.name

      if batch_id
        generic_file.add_relationship("isPartOf", "info:fedora/#{Sufia::Noid.namespaceize(batch_id)}")
      else
        logger.warn "unable to find batch to attach to"
      end
      generic_file.save!
    end
    
    def self.create_content(generic_file, file, file_name, dsid, user)
      generic_file.add_file(file, dsid, file_name)

      save_tries = 0
      begin
        generic_file.save!
      rescue RSolr::Error::Http => error
        logger.warn "GenericFilesController::create_and_save_generic_file Caught RSOLR error #{error.inspect}"
        save_tries+=1
        # fail for good if the tries is greater than 3
        raise error if save_tries >=3
        sleep 0.01
        retry
      end

      generic_file.record_version_committer(user)
      Sufia.queue.push(UnzipJob.new(generic_file.pid)) if generic_file.content.mimeType == 'application/zip'
      Sufia.queue.push(ContentDepositEventJob.new(generic_file.pid, user.user_key))
    end
  end
end
