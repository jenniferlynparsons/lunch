import { connect } from 'react-redux';
import { addRestaurant } from '../actions/restaurants';
import { scroller } from 'react-scroll';
import RestaurantAddForm from '../components/RestaurantAddForm';

// Keep a cache of terms[0] since our geosuggest library doesn't allow us to receive a label different than what is in
// the suggest dropdown
let suggestCache = {};

const mapStateToProps = state => ({
  latLng: state.latLng,
  getSuggestLabel: (suggest) => {
    if (suggest.terms !== undefined && suggest.terms.length > 0) {
      suggestCache[suggest.place_id] = suggest.terms[0].value;
    }
    return suggest.description;
  },
  restaurants: state.restaurants.items
});

const mapDispatchToProps = dispatch => ({
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  handleSuggestSelect: (suggestion, geosuggest) => {
    let name = suggestion.label;
    let address;
    const { placeId, location: { lat, lng } } = suggestion;
    if (suggestCache[placeId] !== undefined) {
      name = suggestCache[placeId];
    }
    if (suggestion.gmaps !== undefined) {
      address = suggestion.gmaps.formatted_address;
    }
    suggestCache = [];
    geosuggest.update('');
    const existingRestaurant = stateProps.restaurants.find(restaurant => restaurant.place_id === placeId);
    if (existingRestaurant === undefined) {
      dispatchProps.dispatch(addRestaurant(name, placeId, address, lat, lng));
    } else {
      scroller.scrollTo(`restaurantListItem_${existingRestaurant.id}`, true, undefined, -20);
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantAddForm);