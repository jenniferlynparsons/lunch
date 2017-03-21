/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { PropTypes } from 'react';
import { intlShape } from 'react-intl';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import { globalMessageDescriptor as gm } from '../../../../helpers/generateMessageDescriptor';
import s from './Admin.css';

class Admin extends React.Component {
  static propTypes = {
    addUserToTeam: PropTypes.func.isRequired,
    adminUserListReady: PropTypes.bool.isRequired,
    fetchUsersIfNeeded: PropTypes.func.isRequired,
    intl: intlShape.isRequired,
    users: PropTypes.array.isRequired,
    title: PropTypes.string.isRequired,
  };

  static defaultState = {
    email: '',
    type: 'user'
  };

  state = Object.assign({}, Admin.defaultState);

  componentWillMount() {
    this.props.fetchUsersIfNeeded();
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.addUserToTeam(this.state.email);
    this.setState(Object.assign({}, Admin.defaultState));
  };

  render() {
    const { adminUserListReady, intl: { formatMessage: f }, users } = this.props;
    const { email, type } = this.state;

    if (!adminUserListReady) {
      return null;
    }

    return (
      <div className={s.root}>
        <div className={s.container}>
          <h1>{this.props.title}</h1>
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.name}</td>
                  <td>{user.email}</td>
                  <td>{f(gm(`${user.type}Role`))}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <h2>Add User</h2>
          <form onSubmit={this.handleSubmit}>
            <label htmlFor="admin-email">
              Email:
            </label>
            <input
              id="admin-email"
              type="email"
              onChange={this.handleChange('email')}
              value={email}
              required
            />
            <label htmlFor="admin-type">
              Type:
            </label>
            <select
              id="admin-type"
              onChange={this.handleChange('type')}
              value={type}
              required
            >
              <option value="user">{f(gm('userRole'))}</option>
              <option value="admin">{f(gm('adminRole'))}</option>
              <option value="owner">{f(gm('ownerRole'))}</option>
            </select>
            <input type="submit" />
          </form>
        </div>
      </div>
    );
  }
}

export default withStyles(s)(Admin);
