# Rewrites `position` as 0..n-1 following the order of the given ids, in a
# single UPDATE, so a drag and drop on the board costs one query per list.
module SequencedPositions
  extend ActiveSupport::Concern

  class_methods do
    def write_positions!(ids)
      where(id: ids).update_all(['position = array_position(ARRAY[?]::bigint[], id) - 1', ids]) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
