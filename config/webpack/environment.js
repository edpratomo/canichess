const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')

const webpack = require('webpack')

environment.plugins.append('Provide',
    new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        jquery: 'jquery/src/jquery',
        Popper: 'popper.js/dist/popper',
        moment: 'moment/moment',
        bootstrap: 'bootstrap',
        BootstrapDialog: 'bootstrap4-dialog/dist/js/bootstrap-dialog'
//        Popper: ['popper.js', 'default']
    })
)

environment.loaders.prepend('erb', erb)
module.exports = environment
