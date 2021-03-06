# frozen_string_literal: true

class ActivityPub::NoteSerializer < ActiveModel::Serializer
  attributes :id, :type, :summary, :content,
             :in_reply_to, :published, :url,
             :attributed_to, :to, :cc, :sensitive

  has_many :media_attachments, key: :attachment
  has_many :virtual_tags, key: :tag

  attribute :atom_uri, key: '_:atomUri', if: :local?
  attribute :in_reply_to_atom_uri, key: '_:inReplyToAtomUri'

  def id
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def type
    'Note'
  end

  def summary
    object.spoiler_text.presence
  end

  def content
    Formatter.instance.format(object)
  end

  def in_reply_to
    return unless object.reply?

    if object.thread.uri.nil? || object.thread.uri.start_with?('http')
      ActivityPub::TagManager.instance.uri_for(object.thread)
    else
      object.thread.url
    end
  end

  def published
    object.created_at.iso8601
  end

  def url
    ActivityPub::TagManager.instance.url_for(object)
  end

  def attributed_to
    ActivityPub::TagManager.instance.uri_for(object.account)
  end

  def to
    ActivityPub::TagManager.instance.to(object)
  end

  def cc
    ActivityPub::TagManager.instance.cc(object)
  end

  def virtual_tags
    object.mentions + object.tags
  end

  def atom_uri
    ::TagManager.instance.uri_for(object)
  end

  def in_reply_to_atom_uri
    return unless object.reply?

    ::TagManager.instance.uri_for(object.thread)
  end

  def local?
    object.account.local?
  end

  class MediaAttachmentSerializer < ActiveModel::Serializer
    include RoutingHelper

    attributes :type, :media_type, :url

    def type
      'Document'
    end

    def media_type
      object.file_content_type
    end

    def url
      object.local? ? full_asset_url(object.file.url(:original, false)) : object.remote_url
    end
  end

  class MentionSerializer < ActiveModel::Serializer
    attributes :type, :href, :name

    def type
      'Mention'
    end

    def href
      ActivityPub::TagManager.instance.uri_for(object.account)
    end

    def name
      "@#{object.account.acct}"
    end
  end

  class TagSerializer < ActiveModel::Serializer
    include RoutingHelper

    attributes :type, :href, :name

    def type
      'Hashtag'
    end

    def href
      tag_url(object)
    end

    def name
      "##{object.name}"
    end
  end
end
