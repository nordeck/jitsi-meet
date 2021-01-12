// @flow

import React from 'react';

import { translate } from '../../base/i18n';
import { Icon, IconClose } from '../../base/icons';

type Props = {

    /**
     * The {@link ModalDialog} closing function.
     */
    onClose: Function,

    /**
     * Invoked to obtain translated strings.
     */
    t: Function
};

/**
 * Custom header of the {@code SecurityDialog}.
 *
 * @returns {React$Element<any>}
 */
function Header({ onClose, t }: Props) {
    return (
        <div
            aria-label = { t('speakerStats.speakerStats') }
            className = 'invite-more-dialog header'>
            { t('speakerStats.speakerStats') }
            <Icon
                ariaLabel = { 'close' }
                onClick = { onClose }
                onKeypress = { onClose }
                src = { IconClose }
                tabIndex = { 0 } />
        </div>
    );
}

export default translate(Header);
