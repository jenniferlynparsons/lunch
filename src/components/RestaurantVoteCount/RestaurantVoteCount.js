import PropTypes from 'prop-types';
import React, { Component } from 'react';
import OverlayTrigger from 'react-bootstrap/lib/OverlayTrigger';
import Tooltip from 'react-bootstrap/lib/Tooltip';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import TooltipUserContainer from '../TooltipUser/TooltipUserContainer';
import s from './RestaurantVoteCount.scss';

export class _RestaurantVoteCount extends Component {
  static propTypes = {
    id: PropTypes.number.isRequired,
    votes: PropTypes.array.isRequired,
    user: PropTypes.object.isRequired
  };

  componentDidUpdate() {
    if (this.el) {
      this.el.classList.add(s.updated);
      this.timeout = setTimeout(() => {
        if (this.el) {
          this.el.classList.remove(s.updated);
        }
      }, 100);
    }
  }

  componentWillUnmount() {
    clearTimeout(this.timeout);
  }

  render() {
    let voteCountContainer = null;
    if (this.props.votes.length > 0) {
      const voteCount = (
        <span>
          <strong>{this.props.votes.length}</strong>
          {this.props.votes.length === 1 ? ' vote' : ' votes'}
        </span>
      );

      let tooltip;
      if (this.props.user.id === undefined) {
        voteCountContainer = voteCount;
      } else {
        tooltip = (
          <Tooltip id={`voteCountTooltip_${this.props.id}`}>{this.props.votes.map(voteId =>
            <TooltipUserContainer key={`voteCountTooltipUser_${voteId}`} voteId={voteId} />
          )}</Tooltip>
        );
        voteCountContainer = (
          <OverlayTrigger
            placement="top"
            overlay={tooltip}
            trigger={['click', 'hover']}
          >
            {voteCount}
          </OverlayTrigger>
        );
      }
    }

    return (
      <span ref={e => { this.el = e; }} className={s.root}>
        {voteCountContainer}
      </span>
    );
  }
}

export default withStyles(s)(_RestaurantVoteCount);
