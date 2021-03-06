<%!
#This is a hack, we should restructure templates to avoid this.
def inherit(context):
    if context.get('trans').webapp.name == 'galaxy' and context.get( 'use_panels', True ):
        return '/webapps/galaxy/base_panels.mako'
    else:
        return '/base.mako'
%>
<%inherit file="${inherit(context)}"/>
<%namespace file="/webapps/tool_shed/common/common.mako" import="*" />

<%def name="init()">
<%
    self.has_left_panel=False
    self.has_right_panel=False
    self.active_view="user"
    self.message_box_visible=False
%>
</%def>

<%namespace file="/message.mako" import="render_msg" />

<%def name="center_panel()">
    ${body()}
</%def>

<%def name="javascripts()">
    ${parent.javascripts()}
</%def>

<%def name="body()">
    <div style="${ 'margin: 1em;' if context.get( 'use_panels', True ) else '' }">

        %if redirect_url:
            <script type="text/javascript">
                top.location.href = '${redirect_url | h}';
            </script>
        %elif message:
            ${render_msg( message, status )}
        %endif

        ## An admin user may be creating a new user account, in which case we want to display the registration form.
        ## But if the current user is not an admin user, then don't display the registration form.
        %if ( cntrller=='admin' and trans.user_is_admin() ) or not trans.user:
            ${render_registration_form()}

            %if trans.app.config.get( 'terms_url', None ) is not None:
                <br/>
                <p>
                    <!-- href="${trans.app.config.get('terms_url', None)}">Terms and Conditions for use of this service</a-->
                </p>
            %endif
        %endif

    </div>
</%def>

<%def name="render_registration_form( form_action=None )">

    <%
        if form_action is None:
            form_action = h.url_for( controller='user', action='create', cntrller=cntrller )
        from galaxy.web.form_builder import CheckboxField
        subscribe_check_box = CheckboxField( 'subscribe' )
    %>

    <script type="text/javascript">
        $(document).ready(function() {

            function validateString(test_string, type) {
                var mail_re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                //var mail_re_RFC822 = /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/;
                var username_re = /^[a-z0-9._\-]{3,255}$/;
                if (type === 'email') {
                    return mail_re.test(test_string);
                } else if (type === 'username'){
                    return username_re.test(test_string);
                }
            }

            function renderError(message) {
                if (!$(".errormessage").size()) {
                    $('<div/>').addClass('errormessage').insertBefore('#registrationForm');
                }
                console.debug( $( '#registrationForm' ) );
                console.debug( '.errormessage:', $( '.errormessage' ) );
                $(".errormessage").html(message);
            }

            $("[name='password']").complexify({'minimumChars':6}, function(valid, complexity){
                var progressBar = $('.progress-bar');
                var color = valid ? 'lightgreen' : 'red';

                progressBar.css('background-color', color);
                progressBar.css({'width': complexity + '%'});
            });

            $('#registration').bind('submit', function(e) {
                $('#send').attr('disabled', 'disabled');

                // we need this value to detect submitting at backend
                var hidden_input = '<input type="hidden" id="create_user_button" name="create_user_button" value="Submit"/>';
                $("#email_input").before(hidden_input);

                var error_text_email = 'The format of the email address is not correct.';
                var error_text_email_long = 'Email address cannot be more than 255 characters in length.';
                var error_text_username_characters = "Public name must contain only lowercase letters, numbers, '.', '_' and '-'. It also has to be between 3 and 255 characters in length.";
                var error_text_password_short = 'Use a password of at least 6 characters';
                var error_text_password_match = "Passwords don't match";
		var error_IP_agreement = "You must accept the User Agreement to create an account.";

                var validForm = true;

                var email = $('#email_input').val();
                var name = $('#name_input').val();
                if (email.length > 255){ renderError(error_text_email_long); validForm = false;}
                else if (!validateString(email,"email")){ renderError(error_text_email); validForm = false;}
                else if (!($('#password_input').val() === $('#password_check_input').val())){ renderError(error_text_password_match); validForm = false;}
                else if ($('#password_input').val().length < 6 ){ renderError(error_text_password_short); validForm = false;}
                else if (name && !(validateString(name,"username"))){ renderError(error_text_username_characters); validForm = false;}
		else if (!$('#accept_IPagreement').is(':checked')){renderError(error_IP_agreement); validForm = false;}

                   if (!validForm) {
                    e.preventDefault();
                    // reactivate the button if the form wasn't submitted
                    $('#send').removeAttr('disabled');
                    }
                });
        });
    </script>

    <div id="registrationForm" class="toolForm center-login" style="border:none;">

        <div class="text-center">
           <br /><p>
               <img class="main-site-logo" src="/static/images/flowtools/home/immportgalaxy_green_sharp.png" alt="ImmPort Galaxy logo" style="height:130px;"/>
            </p>
        </div>
        <br />
        <div>
            <p>Please create an account to access ImmPort Galaxy resources. </p>
            <p style="font-size:12px;"><i>Note this is specific to ImmPort Galaxy and will not grant access to other ImmPort resources or Galaxy instances.</i></p>
        </div>
        

        ## only display the prepopulate form to admins
        %if show_user_prepopulate_form:
            <form name="registration" id="prepopulateform" action="${form_action}" method="post" >
                <input type="hidden" name="session_csrf_token" value="${trans.session_csrf_token}" />
                <div class="toolFormTitle">Pre-populate an account through LDAP</div>
                <div class="form-row">
                    <label>Email address:</label>
                    <input id="email_input" type="text" name="email" value="${email | h}" size="40"/>
                    <input type="hidden" name="redirect" value="${redirect | h}" size="40"/>
                </div>
                <div class="form-row">
                    <label>Username:</label>
                    <input id="name_input" type="text" name="username" size="40" value="${username |h}"/>
                    <div class="toolParamHelp">
                        Depending on your LDAP configuration in your auth_conf.xml you can either provide an
                        email address or username.
                    </div>
                </div>
                <div class="form-row">
                    <input type="submit" id="prepopulate" name="prepopulate_user_button" value="Prepopulate"/>
                </div>
            </form>
            <br />
        %endif
        <form name="registration" id="registration" action="${form_action}" method="post" >
            <input type="hidden" name="session_csrf_token" value="${trans.session_csrf_token}" />
            <!--div class="toolFormTitle">Create account</div-->
            <div class="form-row">
                <!--label>Email address:</label-->
                <input id="email_input" type="text" name="email" value="${email | h}" size="40" placeholder="Email Address" class="login-box" style="width:100%;"/>
                <input type="hidden" name="redirect" value="${redirect | h}" size="40"/>
            </div>
            <div class="form-row">
                <!--label>Password:</label-->
                <input id="password_input" type="password" name="password" value="" size="40" placeholder="Password" class="login-box"  style="width:100%;"/>
            </div>
            <div class="progress">
                <div id="complexity-bar" class="progress-bar" role="progressbar" style="width:100%;">
                    Strength
                </div>
            </div>
            <div class="form-row">
                <!--label>Please confirm password:</label-->
                <input id="password_check_input" type="password" name="confirm" value="" size="40" placeholder="Please confirm password" class="login-box" style="width:100%;"/>
            </div>
            <div class="form-row">
                <!--label>Public name:</label-->
                <input id="name_input" type="text" name="username" size="40" value="${username |h}" placeholder="Public Name" class="login-box" style="width:100%;"/>
                %if t.webapp.name == 'galaxy':
                    <div class="toolParamHelp" style="clear: both;font-size:12px;">
                        Your public name is an identifier that will be used to generate addresses for information
                        you share publicly. Public names must be at least three characters in length and contain only
                        lower-case letters, numbers, dots, underscores, and dashes ('.', '_', '-').
                    </div>
                %else:
                    <div class="toolParamHelp" style="clear: both;font-size:12px;">
                        Your public name provides a means of identifying you publicly within this tool shed. Public
                        names must be at least three characters in length and contain only lower-case letters, numbers,
                        dots, underscores, and dashes ('.', '_', '-'). You cannot change your public name after you have
                        created a repository in this Tool Shed.
                    </div>
                %endif
            </div>
            %if trans.app.config.smtp_server and trans.app.config.mailing_join_addr:
                <div class="form-row">
                    <label>Subscribe to mailing list:</label>
                    ${render_checkbox(subscribe_check_box)}
                    <p>See <a href="https://galaxyproject.org/mailing-lists/" target="_blank">
                    all Galaxy project mailing lists</a>.</p>
                </div>
            %endif
            <div id="for_bears">
            If you see this, please leave following field blank.
            <input type="text" name="bear_field" size="1" value=""/>
            </div>
            <br />
            <div style="text-align: justify;">
                By checking the <strong>"I Accept"</strong> box below,
                you confirm that you have read and accept
                all the terms and conditions without limitation of the
                <strong><a target="_blank" href="http://www.immport.org/agreement">User Agreement</a>
                for the NIAID Immunology Database and Analysis Portal.</strong>
            </div>
            <br />
            <div class="checkbox-inline">
                <label> <input id="accept_IPagreement" type="checkbox" style="margin-top:4px;"/>&nbsp;&nbsp;<strong>I Accept</strong>
                </label>
            </div>

            <div class="form-row">
                <input type="submit" id="send" name="create_user_button" value="Submit" class="btn-primary" style="font-size:14px;"/>
            </div>
        </form>
        %if registration_warning_message:
        <div class="alert alert-danger" style="margin: 30px 12px 12px 12px;">
            ${registration_warning_message}
        </div>
        %endif
    </div>

</%def>
