# Per-Source Clientd

<!-- mdtoc-start -->
&bull; [Per-Source Clientd](#per-source-clientd)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [One Receiver, Multiple Sources](#one-receiver-multiple-sources)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Subscriber's Delivery Controller Handles One Source](#subscribers-delivery-controller-handles-one-source)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [C Code](#c-code)  
&nbsp;&nbsp;&nbsp;&nbsp;&bull; [Java Code](#java-code)  
<!-- TOC created by './mdtoc.pl kb/per-source-clientd.md' (see https://github.com/fordsfords/mdtoc) -->
<!-- mdtoc-end -->

## One Receiver, Multiple Sources

UM supports multiple publishers sending to the same topic.
A subscriber to that topic will receive data from all publishers.
Many subscribers don't really care where an incoming message came from.
But in many cases, it is necessary for the application to track the
sequence of message from each source independently.
For example, a message's UM sequence number monotonically
increases only when tracked per source.
This tracking typically is done by maintaining some source-specific state
using UM's "per-source clientd" feature.

## Subscriber's Delivery Controller Handles One Source

When a subscriber discovers a new source publishing to its topic,
it creates a
"[delivery controller](https://ultramessaging.github.io/currdoc/doc/Design/architecture.html#deliverycontroller)",
an internal UM object that manages delivery of incoming messages from a
specific sourc to the application.
I.e. if there are two publishers for a given topic, that topic's receiver
will have two delivery controllers.
UM deletes delivery controllers that are no longer needed.

Management of UM's internal delivery controllers normally happens
invisibly to the application.
However, UM offers configurable application callbacks that inform the
application as delivery controllers are created and deleted.
This allows the application to create and maintain its own
per-source state.

## C Code
Error checking omitted for clarity.

Assumes you have a "my_per_src_state_t" typedef that holds your desired
per-source state.

````C
/* Callbacks as delivery controllers are created/deleted. */
void *delivery_controller_create_cb(const char *source_name, void *clientd)
{
  char *topic_name = (char *)clientd;
  my_per_src_state_t *per_src_state = (my_per_src_state_t *)malloc(sizeof(my_per_src_state_t));
  ... /* Init the state structure. */
  return per_src_state;
}  /* delivery_controller_create_cb */

int delivery_controller_delete_cb(const char *source_name, void *clientd, void *src_clientd)
{
  char *topic_name = (char *)clientd;
  my_per_src_state_t *per_src_state = (my_per_src_state_t *)src_clientd;
  ...  /* Finalize state before free. */
  free(per_src_state);
  return 0;
}  /* delivery_controller_delete_cb */

/* Receiver callback. */
int my_on_receive(lbm_rcv_t *rcv, lbm_msg_t *msg, void *clientd)
{
  my_per_src_state_t *per_src_state = (my_per_src_state_t *)msg->source_clientd;
  ...  /* Receiver callback has access to per-source state. */
  return 0;
}  /* my_on_receive */

  ...
  lbm_rcv_src_notification_func_t src_notif_func;
  lbm_rcv_topic_attr_t *rcv_attr;
  lbm_topic_t *topic;
  lbm_rcv_t *rcv;
  char *my_topic_name = "MyTopic";

  /* Need to configure the source notification callbacks. */
  lbm_rcv_topic_attr_create(&rcv_attr);
  src_notif_func.create_func = delivery_controller_create_cb;
  src_notif_func.delete_func = delivery_controller_delete_cb;
  /* Make the topic name available to the callbacks. */
  src_notif_func.clientd = my_topic_name;
  lbm_rcv_topic_attr_setopt(rcv_attr, "source_notification_function",
      &src_notif_func, sizeof(src_notif_func));

  /* Now create the receiver. */
  lbm_rcv_topic_lookup(&topic, rcv_ctx, my_topic_name, rcv_attr);
  lbm_rcv_create(&rcv, rcv_ctx, topic, my_on_receive, NULL, NULL);
````

With this code, as delivery controllers come and go, the
delivery_controller_create_cb() and delivery_controller_delete_cb() functions
will be called, and the receiver callback will have access to the per-source
state.

## Java Code
Error checking omitted for clarity.

Assumes you have a "MyPerSrcState" class that holds your desired
per-source state.

````Java
public class MyClass implements LBMReceiverCallback, LBMSourceCreationCallback, LBMSourceDeletionCallback {

  public Object onNewSource(String source, Object cbObj) {
    String myTopic = (String)cbObj;
    MyPerSrcState perSrcState = new MyPerSrcState();
    ...  // Initialize up per-source state.
    return perSrcState;
  }

  public int onSourceDelete(String source, Object cbObj, Object sourceCbObj) {
    MyPerSrcState perSrcState = (MyPerSrcState)sourceCbObj;
    ... // Finalize state.
    return 0;
  }

  @Override
  public int onReceive(Object cbArg, LBMMessage msg) {
    MyPerSrcState perSrcState = (MyPerSrcState)msg.sourceClientObject();
    ... // Receiver callback has access to per-source state.
    return 0;
  }  // onReceive

  ...
    String myTopic = "MyTopic";

    // Need to configure the source notification callbacks.
    LBMReceiverAttributes rcvTopicAttr = new LBMReceiverAttributes();
    // Make the topic name available to the callbacks.
    rcvTopicAttr.setSourceNotificationCallbacks(this, this, myTopic);

    // Now create the receiver.
    LBMTopic topic = ctx.lookupTopic(myTopic, rcvTopicAttr);
    LBMReceiver myRcv = ctx.createReceiver(topic, this, null);
```
