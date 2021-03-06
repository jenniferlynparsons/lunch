/* eslint-env mocha */
/* eslint-disable no-unused-expressions */

import { expect } from 'chai';
import { spy, stub } from 'sinon';
import bodyParser from 'body-parser';
import request from 'supertest';
import express from 'express';
import proxyquire from 'proxyquire';
import SequelizeMock from 'sequelize-mock';
import mockEsmodule from '../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();

const dbMock = new SequelizeMock();

describe('api/main/user', () => {
  let app;
  let UserMock;
  let loggedInSpy;
  let makeApp;
  let updateSpy;

  beforeEach(() => {
    UserMock = dbMock.define('user', {});
    UserMock.getSessionUser = () => Promise.resolve({});

    updateSpy = spy();

    loggedInSpy = spy((req, res, next) => {
      req.user = { // eslint-disable-line no-param-reassign
        get: () => {},
        name: 'Old Name',
        id: 231,
        roles: [],
        update: updateSpy
      };
      next();
    });

    makeApp = (deps, middleware) => {
      const userApi = proxyquireStrict('../main/user', {
        '../../models': mockEsmodule({
          User: UserMock
        }),
        '../helpers/loggedIn': mockEsmodule({
          default: loggedInSpy
        }),
        ...deps
      }).default;

      const server = express();
      server.use(bodyParser.json());
      server.use((req, res, next) => {
        if (middleware) {
          middleware(req, res, next);
        } else {
          next();
        }
      });
      server.use('/', userApi());
      return server;
    };

    app = makeApp();
  });

  describe('PATCH /:id', () => {
    describe('before updating', () => {
      beforeEach(() => request(app).patch('/'));

      it('checks for login', () => {
        expect(loggedInSpy.called).to.be.true;
      });
    });

    describe('without valid parameters', () => {
      let response;
      beforeEach((done) => {
        request(app).patch('/').send({ id: 123 }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 422', () => {
        expect(response.statusCode).to.eq(422);
      });

      it('returns json with error', () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.be.a('string');
      });
    });

    describe('with at least one valid parameter', () => {
      beforeEach(() => request(app).patch('/').send({ name: 'New Name', id: 123 }));

      it('updates user', () => {
        expect(updateSpy.callCount).to.eq(1);
      });
    });

    describe('with bad password', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../../helpers/getPasswordError': mockEsmodule({
            default: () => 'Bad Password!!!'
          })
        });

        request(app).patch('/').send({ password: 'badpassword' }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns 422', () => {
        expect(response.statusCode).to.eq(422);
      });

      it('returns json with error', () => {
        expect(response.body.error).to.eq(true);
        expect(response.body.data.message).to.eq('Bad Password!!!');
      });
    });

    describe('with good password', () => {
      beforeEach(() => {
        app = makeApp({
          '../../helpers/getPasswordError': mockEsmodule({
            default: () => undefined
          }),
          '../../helpers/getUserPasswordUpdates': mockEsmodule({
            default: () => Promise.resolve({
              encrypted_password: 'drowssapdoog'
            })
          })
        });

        return request(app).patch('/').send({ password: 'goodpassword' });
      });

      it('updates with password updates, not password', () => {
        expect(updateSpy.calledWith({ encrypted_password: 'drowssapdoog' })).to.be.true;
      });
    });

    describe('with new name', () => {
      beforeEach(() => request(app).patch('/').send({ name: 'New Name' }));

      it('sets name_changed', () => {
        expect(updateSpy.calledWith({ name: 'New Name', name_changed: true })).to.be.true;
      });
    });

    describe('success', () => {
      let response;
      beforeEach((done) => {
        request(app).patch('/').send({ name: 'New Name' }).then(r => {
          response = r;
          done();
        });
      });

      it('returns 200', () => {
        expect(response.statusCode).to.eq(200);
      });

      it('returns json with user', () => {
        expect(response.body.error).to.eq(false);
        expect(response.body.data).to.be.an('object');
      });
    });

    describe('failure', () => {
      let response;
      beforeEach((done) => {
        app = makeApp({
          '../helpers/loggedIn': mockEsmodule({
            default: spy((req, res, next) => {
              req.user = { // eslint-disable-line no-param-reassign
                get: () => {},
                id: 231,
                roles: [],
                update: stub().throws('Oh No')
              };
              next();
            })
          })
        });

        request(app).patch('/').send({ name: 'New Name' }).then((r) => {
          response = r;
          done();
        });
      });

      it('returns error', () => {
        expect(response.error.text).to.contain('Oh No');
      });
    });
  });
});
