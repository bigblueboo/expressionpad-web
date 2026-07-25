import { describe, expect, it } from 'vitest'
import { bendBytes, ChannelAllocator, MidiIn, MidiOut } from '../src/midi/midi'
import { Store } from '../src/core/state'
import type { VoiceSink } from '../src/audio/sink'

describe('bendBytes', () => {
  it('centers at 8192 for zero bend', () => {
    const [lsb, msb] = bendBytes(0, 48)
    expect((msb << 7) | lsb).toBe(8192)
  })

  it('maxes at full positive range', () => {
    const [lsb, msb] = bendBytes(48, 48)
    expect((msb << 7) | lsb).toBe(16383)
  })

  it('bottoms near zero at full negative range', () => {
    const [lsb, msb] = bendBytes(-48, 48)
    expect((msb << 7) | lsb).toBe(1)
  })

  it('clamps out-of-range bends', () => {
    const [lsb, msb] = bendBytes(100, 48)
    expect((msb << 7) | lsb).toBe(16383)
  })

  it('scales linearly with the range setting', () => {
    const [lsb2, msb2] = bendBytes(1, 2)
    const [lsb48, msb48] = bendBytes(24, 48)
    expect((msb2 << 7) | lsb2).toBe((msb48 << 7) | lsb48)
  })

  it('produces valid 7-bit data bytes', () => {
    for (const semis of [-48, -1.3, 0, 0.5, 7, 48]) {
      const [lsb, msb] = bendBytes(semis, 48)
      expect(lsb).toBeGreaterThanOrEqual(0)
      expect(lsb).toBeLessThanOrEqual(127)
      expect(msb).toBeGreaterThanOrEqual(0)
      expect(msb).toBeLessThanOrEqual(127)
    }
  })
})

describe('ChannelAllocator', () => {
  it('hands out distinct member channels 1-15', () => {
    const alloc = new ChannelAllocator()
    const channels = new Set<number>()
    for (let id = 0; id < 15; id++) channels.add(alloc.acquire(id))
    expect(channels.size).toBe(15)
    expect(Math.min(...channels)).toBe(1)
    expect(Math.max(...channels)).toBe(15)
  })

  it('is idempotent for the same id', () => {
    const alloc = new ChannelAllocator()
    expect(alloc.acquire(7)).toBe(alloc.acquire(7))
  })

  it('recycles released channels with maximum reuse distance', () => {
    const alloc = new ChannelAllocator(1, 3)
    const a = alloc.acquire(1)
    alloc.acquire(2)
    alloc.acquire(3)
    alloc.release(1)
    // Channel `a` goes to the back of the queue; a 4th voice steals... no:
    // there is exactly one free channel now, so it must be `a`.
    expect(alloc.acquire(4)).toBe(a)
  })

  it('steals the oldest held channel when exhausted', () => {
    const alloc = new ChannelAllocator(1, 2)
    const first = alloc.acquire(1)
    alloc.acquire(2)
    const third = alloc.acquire(3)
    expect(third).toBe(first)
    expect(alloc.channelOf(1)).toBeUndefined()
  })
})

class SpySink implements VoiceSink {
  ons: Array<[number, number, number]> = []
  offs: number[] = []
  noteOn(id: number, pitch: number, vel: number) { this.ons.push([id, pitch, vel]) }
  glide() {}
  pressure() {}
  noteOff(id: number) { this.offs.push(id) }
  allOff() {}
}

describe('MidiIn', () => {
  it('routes note on/off pairs to the sink', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    expect(sink.ons).toHaveLength(1)
    expect(sink.ons[0][1]).toBe(60)
    expect(sink.ons[0][2]).toBeCloseTo(100 / 127)
    midiIn.handle(new Uint8Array([0x80, 60, 0]))
    expect(sink.offs).toEqual([sink.ons[0][0]])
  })

  it('treats velocity-0 note-on as note-off', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 64, 90]))
    midiIn.handle(new Uint8Array([0x90, 64, 0]))
    expect(sink.offs).toHaveLength(1)
  })

  it('ignores messages when disabled', () => {
    const store = new Store()
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    expect(sink.ons).toHaveLength(0)
  })

  it('releases held notes when detached', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    midiIn.detach()
    expect(sink.offs).toEqual([sink.ons[0][0]])
  })

  it('releases an overlapping note-on before replacing its id', () => {
    const store = new Store()
    store.set('midi.inEnabled', true)
    const sink = new SpySink()
    const midiIn = new MidiIn(store, sink)
    midiIn.handle(new Uint8Array([0x90, 60, 100]))
    midiIn.handle(new Uint8Array([0x90, 60, 90]))
    expect(sink.offs).toEqual([sink.ons[0][0]])
    midiIn.handle(new Uint8Array([0x80, 60, 0]))
    expect(sink.offs).toEqual([sink.ons[0][0], sink.ons[1][0]])
  })
})

function midiHarness() {
  const store = new Store()
  const sentA: number[][] = []
  const sentB: number[][] = []
  const a = { id: 'a', name: 'A', send: (bytes: number[]) => sentA.push([...bytes]) } as unknown as MIDIOutput
  const b = { id: 'b', name: 'B', send: (bytes: number[]) => sentB.push([...bytes]) } as unknown as MIDIOutput
  const midi = new MidiOut(store)
  midi.access = {
    outputs: new Map([['a', a], ['b', b]]),
    inputs: new Map(),
  } as unknown as MIDIAccess
  store.set('midi.outputId', 'a')
  sentA.length = 0
  sentB.length = 0
  return { store, midi, sentA, sentB }
}

describe('MidiOut', () => {
  it('terminates a stolen note before reusing its channel', () => {
    const { midi, sentA } = midiHarness()
    for (let id = 1; id <= 15; id++) midi.noteOn(id, 59 + id, 1)
    const before = sentA.length
    midi.noteOn(16, 75, 1)
    expect(sentA.slice(before, before + 3)).toEqual([
      [0x81, 60, 0],
      [0xe1, 0, 64],
      [0x91, 75, 127],
    ])
    const afterSteal = sentA.length
    midi.glide(1, 62.5)
    expect(sentA).toHaveLength(afterSteal)
  })

  it('releases active notes on their original destination when switching', () => {
    const { store, midi, sentA, sentB } = midiHarness()
    midi.noteOn(1, 60, 1)
    store.set('midi.outputId', 'b')
    expect(sentA).toContainEqual([0x81, 60, 0])
    expect(sentB).not.toContainEqual([0x81, 60, 0])
  })

  it('configures MPE zone and member-channel bend range', () => {
    const { store, sentA } = midiHarness()
    store.set('midi.bendRange', 24)
    expect(sentA).toContainEqual([0xb0, 101, 0])
    expect(sentA).toContainEqual([0xb0, 100, 6])
    expect(sentA).toContainEqual([0xb0, 6, 15])
    expect(sentA).toContainEqual([0xb1, 100, 0])
    expect(sentA).toContainEqual([0xb1, 6, 24])
  })

  it('re-sends held bends after changing the configured range', () => {
    const { store, midi, sentA } = midiHarness()
    midi.noteOn(1, 60.5, 1)
    sentA.length = 0
    store.set('midi.bendRange', 24)
    const [lsb, msb] = bendBytes(-0.5, 24)
    expect(sentA.at(-1)).toEqual([0xe1, lsb, msb])
  })

  it('panic sends sustain-off, all-sound-off, all-notes-off, and bend center', () => {
    const { midi, sentA } = midiHarness()
    midi.noteOn(1, 60, 1)
    sentA.length = 0
    midi.allOff()
    expect(sentA).toContainEqual([0xb1, 64, 0])
    expect(sentA).toContainEqual([0xb1, 120, 0])
    expect(sentA).toContainEqual([0xb1, 123, 0])
    expect(sentA).toContainEqual([0xe1, 0, 64])
  })
})
