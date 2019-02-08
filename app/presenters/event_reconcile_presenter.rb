# frozen_string_literal: true

class EventReconcilePresenter < EventWithEffortsPresenter
  def post_initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :current_user], exclusive: [:event, :params, :current_user], class: self.class)
    unreconciled_batch.each(&:suggest_close_match)
  end

  def unreconciled_batch
    @unreconciled_batch ||= event.unreconciled_efforts.order(:last_name).limit(20)
  end

  private

end
