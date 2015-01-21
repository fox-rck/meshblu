_            = require 'lodash'
uuid         = require 'node-uuid'
bcrypt       = require 'bcrypt'
TestDatabase = require '../test-database'

describe 'Update Device', ->
  beforeEach (done) ->
    @sut = require '../../lib/updateDevice'
    @getDevice = sinon.stub()
    TestDatabase.open (error, database) =>
      @database = database
      @devices  = @database.collection 'devices'
      @dependencies = {database: @database, getDevice: @getDevice}
      done error

  afterEach ->
    @database.close()

  it 'should be a function', ->
    expect(@sut).to.be.a 'function'

  describe 'when called with nothing', ->
    beforeEach (done) ->
      @getDevice.yields null
      storeError = (@error, device) => done()
      @sut null, null, storeError, @dependencies

    it 'should call its callback with an error', ->
      expect(@error).to.exist

  describe 'when called with a uuid that doesnt exist', ->
    beforeEach (done) ->
      @getDevice.yields null
      storeError = (@error, device) => done()
      @sut 'not-real', null, storeError, @dependencies

    it 'should call its callback with an error', ->
      expect(@error).to.exist

  describe 'when a device exists', ->
    beforeEach (done) ->
      @uuid = uuid.v1()
      @rawToken = 'akuma'
      @token = bcrypt.hashSync(@rawToken, 8)
      @originalDevice = {uuid: @uuid, name: 'hadoken', token : @token, online :true}
      @devices.insert _.clone(@originalDevice), done

    describe 'when update is called with that uuid and different name', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {name: 'shakunetsu'}, done, @dependencies

      it 'should update the record', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) ->
          done error if error?
          expect(device.name).to.equal 'shakunetsu'
          done()

    describe 'when update is called with that uuid and the same name', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {name: 'hadoken'}, done, @dependencies

      it 'should update the record', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) ->
          done error if error?
          expect(device.name).to.equal 'hadoken'
          done()

    describe 'when update is called with one good and one bad param', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {name: 'guile', '$natto': 'fermented soybeans'}, done, @dependencies

      it 'should update the record', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) ->
          done error if error?
          expect(device.name).to.equal 'guile'
          expect(device['$natto']).to.not.exist
          done()

    describe 'when update is called with a nested bad param', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {name: 'guile', foo: {'$natto': 'fermented soybeans'}}, done, @dependencies

      it 'should update the record', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) ->
          done error if error?
          expect(device.name).to.equal 'guile'
          expect(device.foo).to.deep.equal {}
          done()

    describe 'when update is called with that uuid and the same name', ->
      beforeEach (done) ->
        @getDevice.yields null
        storeDevice = (@error, @device) => done()
        @sut @uuid, {name: 'hadoken'}, storeDevice, @dependencies

      it 'should update the record', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) =>
          return done error if error?
          expect(device.name).to.equal 'hadoken'
          done()

    describe 'when updated with a token', ->
      beforeEach (done) ->
        @getDevice.yields null
        @device = { name: 'ken masters', token : 'masters ken' }
        @sut @uuid, @device, done, @dependencies

      it 'should update a hash of the token', (done) ->
        @database.devices.findOne { uuid: @uuid }, (error, storeDevice) =>
          return done error if error?
          expect(bcrypt.compareSync(@device.token, storeDevice.token)).to.be.true
          done()

    describe 'when updated without a token', ->
      beforeEach (done) ->
        @getDevice.yields null
        @device = { name: 'shin akuma' }
        @sut @uuid, @device, done, @dependencies

      it 'should not update the token', (done) ->
        @database.devices.findOne { uuid: @uuid }, (error, storeDevice) =>
          return done error if error?
          expect(bcrypt.compareSync(@rawToken, storeDevice.token)).to.be.true
          done()

    describe 'when updated with an online of "false"', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {online: 'false'}, done, @dependencies

      it 'should create a device with an online of true', (done) ->
        @devices.findOne (error, device) =>
          expect(device.online).to.be.true
          done()

    describe 'when updated with an online of false', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {online: false}, done, @dependencies

      it 'should create a device with an online of true', (done) ->
        @devices.findOne (error, device) =>
          expect(device.online).to.be.false
          done()

    describe 'when updated without a timestamp', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {}, done, @dependencies

      it 'should create a timestamp', (done) ->
        @devices.findOne (error, device) =>
          expect(device.timestamp).to.exist
          done()

  describe 'when a device exists with online = true', ->
    beforeEach (done) ->
      @uuid = uuid.v1()
      @devices.insert {uuid: @uuid, online: true}, done

    describe 'when called without online', ->
      beforeEach (done) ->
        @getDevice.yields null
        @sut @uuid, {}, done, @dependencies

      it 'should not modify online', (done) ->
        @devices.findOne {uuid: @uuid}, (error, device) =>
          done error if error?
          expect(device.online).to.be.true
          done()