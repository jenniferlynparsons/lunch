import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './HomePage.scss';
import RestaurantMapContainer from '../../containers/RestaurantMapContainer';
import RestaurantListContainer from '../../containers/RestaurantListContainer';
import RestaurantAddFormContainer from '../../containers/RestaurantAddFormContainer';
import TagFilterFormContainer from '../../containers/TagFilterFormContainer';

const title = 'Lunch';

export class _HomePage extends Component {

  static contextTypes = {
    onSetTitle: PropTypes.func.isRequired
  };

  static propTypes = {
    user: PropTypes.object.isRequired,
    fetchRestaurantsIfNeeded: PropTypes.func.isRequired
  };

  componentWillMount() {
    this.context.onSetTitle(title);
    this.props.fetchRestaurantsIfNeeded();
  }

  render() {
    let restaurantAddForm = null;
    if (typeof this.props.user.id === 'number') {
      restaurantAddForm = <RestaurantAddFormContainer />;
    }

    return (
      <div className={s.root}>
        <RestaurantMapContainer />
        {restaurantAddForm}
        <TagFilterFormContainer />
        <div className={s.restaurantList}>
          <RestaurantListContainer />
        </div>
      </div>
    );
  }

}

export default withStyles(_HomePage, s);
