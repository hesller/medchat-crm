json.payload do
  json.partial! 'api/v1/models/pipeline_item', item: @item
end
