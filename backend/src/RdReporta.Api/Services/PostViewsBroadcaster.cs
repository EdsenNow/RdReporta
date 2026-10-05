using System.Collections.Concurrent;
using System.Threading.Channels;

namespace RdReporta.Api.Services;

public sealed record PostViewsUpdate(Guid PostId, int ViewsCount);

// One bounded queue per connection prevents a slow phone from retaining events.
public sealed class PostViewsBroadcaster
{
    private readonly ConcurrentDictionary<Guid, Subscription> _subscriptions = new();

    public Subscription Subscribe(HashSet<Guid> postIds)
    {
        var subscription = new Subscription(this, postIds);
        _subscriptions[subscription.Id] = subscription;
        return subscription;
    }

    public void Publish(Guid postId, int viewsCount)
    {
        foreach (var subscription in _subscriptions.Values)
            if (subscription.PostIds.Contains(postId))
                subscription.Queue.Writer.TryWrite(new(postId, viewsCount));
    }

    public sealed class Subscription : IDisposable
    {
        private readonly PostViewsBroadcaster _owner;
        internal Guid Id { get; } = Guid.NewGuid();
        internal HashSet<Guid> PostIds { get; }
        internal Channel<PostViewsUpdate> Queue { get; } = Channel.CreateBounded<PostViewsUpdate>(
            new BoundedChannelOptions(128) { FullMode = BoundedChannelFullMode.DropOldest });
        public ChannelReader<PostViewsUpdate> Reader => Queue.Reader;

        internal Subscription(PostViewsBroadcaster owner, HashSet<Guid> postIds)
        {
            _owner = owner;
            PostIds = postIds;
        }

        public void Dispose()
        {
            _owner._subscriptions.TryRemove(Id, out _);
            Queue.Writer.TryComplete();
        }
    }
}
