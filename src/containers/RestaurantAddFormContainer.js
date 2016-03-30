import { connect } from 'react-redux';
import { addRestaurant } from '../actions/restaurants';
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
  }
});

const mapDispatchToProps = dispatch => ({
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
    dispatch(addRestaurant(name, placeId, address, lat, lng));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(RestaurantAddForm);