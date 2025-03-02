{% set models_to_generate = codegen.get_models(directory = 'core', prefix='stg') %} -- generate a model yml for everything in the staging directory and give it the prefix 'stg'
{{codegen.generate_model_yaml(
    model_names = models_to_generate
) }}