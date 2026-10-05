using System.Buffers.Binary;

namespace RdReporta.Api.Services;

public static class VideoSecurityHelper
{
    public static readonly TimeSpan MaxDuration = TimeSpan.FromMinutes(3);

    public static bool TryReadDuration(
        Stream stream,
        string extension,
        CancellationToken cancellationToken,
        out TimeSpan duration)
    {
        duration = default;
        if (!stream.CanRead || !stream.CanSeek) return false;

        var originalPosition = stream.Position;
        try
        {
            stream.Position = 0;
            var seconds = extension.ToLowerInvariant() switch
            {
                ".mp4" or ".mov" or ".m4v" or ".3gp" => ReadIsoMediaDuration(stream, cancellationToken),
                ".webm" or ".mkv" => ReadEbmlDuration(stream, cancellationToken),
                _ => null
            };
            if (seconds is null || !double.IsFinite(seconds.Value) || seconds <= 0
                || seconds > TimeSpan.MaxValue.TotalSeconds)
                return false;

            duration = TimeSpan.FromSeconds(seconds.Value);
            return true;
        }
        catch (EndOfStreamException)
        {
            return false;
        }
        catch (InvalidDataException)
        {
            return false;
        }
        catch (OverflowException)
        {
            return false;
        }
        finally
        {
            stream.Position = originalPosition;
        }
    }

    private static double? ReadIsoMediaDuration(Stream stream, CancellationToken ct)
    {
        var fileEnd = stream.Length;
        while (stream.Position + 8 <= fileEnd)
        {
            ct.ThrowIfCancellationRequested();
            var box = ReadIsoBox(stream, fileEnd);
            if (box.Type == "moov")
                return ReadMovieHeaderDuration(stream, box.End, ct);
            stream.Position = box.End;
        }
        return null;
    }

    private static double? ReadMovieHeaderDuration(Stream stream, long moovEnd, CancellationToken ct)
    {
        while (stream.Position + 8 <= moovEnd)
        {
            ct.ThrowIfCancellationRequested();
            var box = ReadIsoBox(stream, moovEnd);
            if (box.Type == "mvhd")
            {
                Span<byte> header = stackalloc byte[32];
                var available = box.End - stream.Position;
                var needed = available >= 32 ? 32 : available >= 20 ? 20 : 0;
                if (needed == 0 || !ReadExactly(stream, header[..(int)needed])) return null;

                uint timescale;
                ulong units;
                if (header[0] == 0 && needed >= 20)
                {
                    timescale = BinaryPrimitives.ReadUInt32BigEndian(header[12..16]);
                    units = BinaryPrimitives.ReadUInt32BigEndian(header[16..20]);
                }
                else if (header[0] == 1 && needed >= 32)
                {
                    timescale = BinaryPrimitives.ReadUInt32BigEndian(header[20..24]);
                    units = BinaryPrimitives.ReadUInt64BigEndian(header[24..32]);
                }
                else
                    return null;

                return timescale == 0 || units == 0 ? null : (double)units / timescale;
            }
            stream.Position = box.End;
        }
        return null;
    }

    private static IsoBox ReadIsoBox(Stream stream, long parentEnd)
    {
        Span<byte> header = stackalloc byte[16];
        var start = stream.Position;
        if (!ReadExactly(stream, header[..8])) throw new EndOfStreamException();
        var size32 = BinaryPrimitives.ReadUInt32BigEndian(header[..4]);
        var type = System.Text.Encoding.ASCII.GetString(header[4..8]);
        var headerSize = 8L;
        ulong size = size32;
        if (size32 == 1)
        {
            if (!ReadExactly(stream, header[8..16])) throw new EndOfStreamException();
            size = BinaryPrimitives.ReadUInt64BigEndian(header[8..16]);
            headerSize = 16;
        }
        else if (size32 == 0)
            size = (ulong)(parentEnd - start);

        if (size < (ulong)headerSize || size > long.MaxValue)
            throw new InvalidDataException("Invalid ISO media box size.");
        var end = checked(start + (long)size);
        if (end > parentEnd) throw new InvalidDataException("ISO media box exceeds its parent.");
        return new IsoBox(type, end);
    }

    private static double? ReadEbmlDuration(Stream stream, CancellationToken ct)
    {
        var fileEnd = stream.Length;
        while (stream.Position < fileEnd)
        {
            ct.ThrowIfCancellationRequested();
            var id = ReadEbmlInteger(stream, false, 4);
            var size = ReadEbmlInteger(stream, true, 8);
            var elementEnd = size.Unknown ? fileEnd : CheckedEnd(stream.Position, size.Value, fileEnd);
            if (id.Value == 0x18538067)
                return ReadSegmentDuration(stream, elementEnd, ct);
            stream.Position = elementEnd;
        }
        return null;
    }

    private static double? ReadSegmentDuration(Stream stream, long segmentEnd, CancellationToken ct)
    {
        var elements = 0;
        while (stream.Position < segmentEnd && elements++ < 100_000)
        {
            ct.ThrowIfCancellationRequested();
            var id = ReadEbmlInteger(stream, false, 4);
            var size = ReadEbmlInteger(stream, true, 8);
            if (size.Unknown) return null;
            var elementEnd = CheckedEnd(stream.Position, size.Value, segmentEnd);
            if (id.Value == 0x1549A966)
                return ReadInfoDuration(stream, elementEnd, ct);
            stream.Position = elementEnd;
        }
        return null;
    }

    private static double? ReadInfoDuration(Stream stream, long infoEnd, CancellationToken ct)
    {
        ulong timecodeScale = 1_000_000;
        double? duration = null;
        while (stream.Position < infoEnd)
        {
            ct.ThrowIfCancellationRequested();
            var id = ReadEbmlInteger(stream, false, 4);
            var size = ReadEbmlInteger(stream, true, 8);
            if (size.Unknown) return null;
            var elementEnd = CheckedEnd(stream.Position, size.Value, infoEnd);
            if (id.Value == 0x2AD7B1)
                timecodeScale = ReadUnsigned(stream, size.Value);
            else if (id.Value == 0x4489)
                duration = ReadFloat(stream, size.Value);
            stream.Position = elementEnd;
        }
        return duration is > 0 && timecodeScale > 0
            ? duration.Value * timecodeScale / 1_000_000_000d
            : null;
    }

    private static EbmlInteger ReadEbmlInteger(Stream stream, bool removeMarker, int maxLength)
    {
        var first = stream.ReadByte();
        if (first < 0) throw new EndOfStreamException();
        var marker = 0x80;
        var length = 1;
        while ((first & marker) == 0 && length <= 8)
        {
            marker >>= 1;
            length++;
        }
        if (marker == 0 || length > maxLength) throw new InvalidDataException("Invalid EBML integer.");

        ulong value = removeMarker ? (uint)(first & (marker - 1)) : (uint)first;
        for (var i = 1; i < length; i++)
        {
            var next = stream.ReadByte();
            if (next < 0) throw new EndOfStreamException();
            value = (value << 8) | (uint)next;
        }
        var unknown = removeMarker && value == ((1UL << (length * 7)) - 1);
        return new EbmlInteger(value, unknown);
    }

    private static ulong ReadUnsigned(Stream stream, ulong size)
    {
        if (size is 0 or > 8) throw new InvalidDataException("Invalid EBML unsigned integer.");
        ulong value = 0;
        for (ulong i = 0; i < size; i++)
        {
            var next = stream.ReadByte();
            if (next < 0) throw new EndOfStreamException();
            value = (value << 8) | (uint)next;
        }
        return value;
    }

    private static double ReadFloat(Stream stream, ulong size)
    {
        Span<byte> bytes = stackalloc byte[8];
        if (size == 4 && ReadExactly(stream, bytes[..4]))
            return BitConverter.Int32BitsToSingle(BinaryPrimitives.ReadInt32BigEndian(bytes[..4]));
        if (size == 8 && ReadExactly(stream, bytes))
            return BitConverter.Int64BitsToDouble(BinaryPrimitives.ReadInt64BigEndian(bytes));
        throw new InvalidDataException("Invalid EBML floating-point value.");
    }

    private static long CheckedEnd(long start, ulong size, long parentEnd)
    {
        if (size > long.MaxValue) throw new InvalidDataException("Element is too large.");
        var end = checked(start + (long)size);
        if (end > parentEnd) throw new InvalidDataException("Element exceeds its parent.");
        return end;
    }

    private static bool ReadExactly(Stream stream, Span<byte> buffer)
    {
        var read = 0;
        while (read < buffer.Length)
        {
            var current = stream.Read(buffer[read..]);
            if (current == 0) return false;
            read += current;
        }
        return true;
    }

    private readonly record struct IsoBox(string Type, long End);
    private readonly record struct EbmlInteger(ulong Value, bool Unknown);
}
