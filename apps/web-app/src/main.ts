import { mount } from 'svelte';
import App from 'shared-ui';
import 'shared-ui/app.css';

const app = mount(App, {
    target: document.getElementById('app')!,
});

export default app;
