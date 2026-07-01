# frozen_string_literal: true

require_relative "../../../impl/request_dto"
require_relative "../../../task/ordering_config"

module Operaton
  module Bpm
    module Client
      module Topic
        module Impl
          module Dto
            # Mirrors org.operaton.bpm.client.topic.impl.dto.FetchAndLockRequestDto
            # (annotated @JsonInclude(NON_NULL) in Java — nil fields are omitted).
            class FetchAndLockRequestDto < Client::Impl::RequestDto
              attr_reader :max_tasks, :async_response_timeout, :topics, :sorting

              def initialize(worker_id, max_tasks, async_response_timeout, topics,
                             use_priority = true, ordering_config = Task::OrderingConfig.empty)
                super(worker_id)
                @max_tasks = max_tasks
                @use_priority = use_priority
                @async_response_timeout = async_response_timeout
                @topics = topics
                @sorting = ordering_config.to_sorting_dtos
              end

              def use_priority?
                @use_priority
              end

              def as_json
                json = super.merge(
                  "maxTasks" => max_tasks,
                  "usePriority" => use_priority?,
                  "asyncResponseTimeout" => async_response_timeout,
                  "topics" => topics.map(&:as_json),
                  "sorting" => sorting.map(&:as_json)
                )
                json.compact
              end
            end
          end
        end
      end
    end
  end
end
